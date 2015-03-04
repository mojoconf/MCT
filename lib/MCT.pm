package MCT;

use Mojo::Base 'Mojolicious';

our $VERSION = '0.01';

use Mojo::Pg;
use Mojo::Eventbrite;
use MCT::Model;

has pg => sub { Mojo::Pg->new(shift->config->{db}) };

sub migrations {
  my $app = shift;
  my $migrations = $app->renderer->template_path({template => 'sql/migrations', format => 'sql'});
  $app->pg->migrations->from_file($migrations);
}

sub startup {
  my $app = shift;

  $app->plugin('Config' => file => $ENV{MOJO_CONFIG} || $app->home->rel_file('mct.conf'));

  $app->helper('eventbrite'         => sub { $_[0]->stash->{'mct.eventbrite'} ||= Mojo::Eventbrite->new });
  $app->helper('model.db'           => sub { $_[0]->stash->{'mct.db'} ||= $_[0]->app->pg->db });
  $app->helper('model.conference'   => sub { MCT::Model->new_object(Conference => db => shift->model->db, @_) });
  $app->helper('model.identity'     => sub { MCT::Model->new_object(Identity => db => shift->model->db, @_) });
  $app->helper('model.presentation' => sub { MCT::Model->new_object(Presentation => db => shift->model->db, @_) });
  $app->helper('model.user'         => sub { MCT::Model->new_object(User => db => shift->model->db, @_) });

  $app->_setup_database;
  $app->_setup_secrets;
  $app->plugin('MCT::Plugin::Auth');
  $app->_ensure_conference;
  $app->_routes;
  $app->_auto_routes;
  $app->plugin('MCT::Plugin::Mock') if $ENV{MCT_MOCK};
}

sub _auto_routes {
  my $app = shift;
  my $r = $app->routes;

  for my $p (@{$app->renderer->paths}) {
    File::Find::find(
      {
        wanted => sub {
          my $template = File::Spec->abs2rel($File::Find::name, $p);
          my $path;
          $template =~ s!\.html\.ep$!! or return;
          $path = $template;
          $path =~ s!.*auto\W+!!;
          $app->log->debug("Adding auto route /$path for $template");
          $r->get("/$path")->to(template => $template)->name($path);
        },
        no_chdir => 1,
      },
      "$p/auto",
    );
  }
}

sub _ensure_conference {
  my $app = shift;
  my $conference = $app->config('conference');
  my $model = $app->model->conference(%$conference);

  $app->defaults(conference => $model->load->save($conference));
}

sub _routes {
  my $app = shift;
  my $r = $app->routes;

  $r->get('/')->to('home#landing_page')->name('landing_page');
  $r->get('/connect')->to('user#connect')->name('connect');
  $r->get('/logout')->to('user#logout')->name('logout');
  $r->authorized->get('/profile')->to('user#profile')->name('profile');
  $r->any('/presentations/:url_name')->to('presentation#')->name('presentation')
    ->tap(get => {action => 'show'})
    ->tap(put => {action => 'save'});

  # back compat
  $app->plugin('MCT::Plugin::ACT' => { url => 'http://www.mojoconf.org/mojo2014' });
}

sub _setup_database {
  my $app = shift;
  my $migrations;

  unless ($app->config->{db} ||= $ENV{MCT_DATABASE_DSN}) {
    my $db = sprintf 'postgresql://%s@/mct_%s', (getpwuid $<)[0] || 'postgresql', $app->mode;
    $app->config->{db} = $db;
    $app->log->warn("Using default database '$db'. (Neither MCT_DATABASE_DSN or config file was set up)");
  }

  $migrations = $app->migrations;
  $migrations->migrate(0) if $ENV{MCT_RESET_DATABASE}; # useful while developing
  $migrations->migrate;
}

sub _setup_secrets {
  my $app = shift;
  my $secrets = $app->config('secrets') || [];

  unless (@$secrets) {
    my $unsafe = join ':', $app->config('db'), $<, $(, $^X, $^O, $app->home;
    $app->log->warn('Using default (unsafe) session secrets. (Config file was not set up)');
    $secrets = [Mojo::Util::md5_sum($unsafe)];
  }

  $app->secrets($secrets);
}

1;

=head1 NAME

MCT - Mojo conference toolkit

=head1 DESCRIPTION

L<MCT> is a L<Mojolicious> based web application for running conferences.

THIS PROJECT IS UNDER HEAVY DEVELOPMENT. ANY CHANGES CAN HAPPEN.

=head2 Features

The features below are ideas for what might be implemented:

=over 4

=item * Single sign on with OAuth2

We do not want to store user passwords, so instead we should use
L<Mojolicious::Plugin::OAuth2> to connect existing systems to L<MCT>.

=item * Talk admin

All conference users can post talks. Conference admins can move talks
into a schedule by accepting or rejecting talks.

=item * News

A very simple L<Text::Markdown> based editor for news items and generation of an
L<atom news feed|XML::Atom::Feed>.

=item * User management

Simple user groups need to be implemented: Admin and regular users.

=item * Eventbrite hooks

Would be nice if L<Eventbrite|http://developer.eventbrite.com/docs/webhooks-summary/>
could push data back to L<MCT> when changes are made.

=item * Wiki

A very simple L<Text::Markdown> based editor for wiki pages.

=back

=head1 REQUIREMENTS

=over 4

=item * A PostgreSQL database.

Conference data, user information and talks are stored in the local database.

=item * An L<http://eventbrite.com/> account.

Eventbrite is used for single sign on, and management for payments and meta
data.

=back

=head1 AUTHOR

Glen Hinkle E<lt>tempire@cpan.org<gt>

Jan Henning Thorsen, E<lt>jhthorsen@cpan.orgE<gt>

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2014 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
