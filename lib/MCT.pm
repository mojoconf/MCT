package MCT;

use Mojo::Base 'Mojolicious';

our $VERSION = '0.01';

use Mojo::Pg;
use MCT::Model;

has pg => sub { Mojo::Pg->new(shift->config->{db}) };

sub migrations {
  my $app = shift;
  $app->pg->migrations->from_file($app->home->rel_file('mct.sql'));
}

sub startup {
  my $app = shift;

  $app->plugin('Config' => file => $ENV{MOJO_CONFIG} || $app->home->rel_file('mct.conf'));
  $app->plugin('MCT::Plugin::Auth');

  $app->helper('model.db'           => sub { $_[0]->stash->{'mct.db'} ||= $_[0]->app->pg->db });
  $app->helper('model.conference'   => sub { MCT::Model->new_object(Conference => db => shift->model->db, @_) });
  $app->helper('model.identity'     => sub { MCT::Model->new_object(Identity => db => shift->model->db, @_) });
  $app->helper('model.presentation' => sub { MCT::Model->new_object(Presentation => db => shift->model->db, @_) });
  $app->helper('model.user'         => sub { MCT::Model->new_object(User => db => shift->model->db, @_) });

  $app->_setup_database;
  $app->_setup_secrets;
  $app->_routes;
  $app->_will_remove_this_once_prod_is_up_to_date;
}

sub _routes {
  my $app = shift;
  my $norm = $app->routes;
  my $auth = $app->connect->authorized_route($norm);
  my $conf;

  $norm->get('/')->to('conference#latest_conference');
  $auth->get('/user/profile')->to('user#profile')->name('user.profile');

  # back compat
  $app->plugin('MCT::Plugin::ACT' => { url => 'http://www.mojoconf.org/mojo2014' });

  $conf = $app->routes->under('/:cid')->to('conference#load');
  $conf->get('/')->to('conference#landing_page')->name('landing_page');
  $norm->post('/')->to('conference#create')->name('conference.create');
  $conf->any('/presentations')->to('presentation#')->name('presentations')
    ->tap(get  => {template => 'presentation/edit'})
    ->tap(post => {action   => 'save'})
    ->any('/:url_name')->name('presentation')
      ->tap(get => {action => 'show'})
      ->tap(put => {action => 'update'});
  $conf->get('/:page')->to('conference#page')->name('conference.page');
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

sub _will_remove_this_once_prod_is_up_to_date {
  my $app = shift;

  if ($0 =~ /\.t$/) {
    $app->log->debug('batman: will not mess with the database from the app, when running unit tests');
    return;
  }

  $app->log->warn('batman: purging the whole conference database to make sure we are up to date in production');
  $app->model->db->query('DELETE FROM conferences');
  $app->model->conference(
    name => 'Mojoconf 2015',
    identifier => '2015',
    tagline => 'All the Mojo you can conf.',
  )->save(sub {});
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

=item * Wiki

A very simple L<Text::Markdown> based editor for wiki pages.

=back

=head1 REQUIREMENTS

=over 4

=item * A PostgreSQL database.

Conference data, user information and talks are stored in the local database.

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
