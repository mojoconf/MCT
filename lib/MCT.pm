package MCT;

use Mojo::Base 'Mojolicious';

our $VERSION = '0.01';

use Mojo::Pg;
use MCT::Model::Conference;
use MCT::Model::User;
use MCT::Model::Presentation;

has pg => sub { Mojo::Pg->new(shift->config->{db}) };

sub migrations {
  my $app = shift;
  $app->pg->migrations->from_file($app->home->rel_file('mct.sql'));
}

sub startup {
  my $app = shift;

  $app->plugin(Config => {
    file => $app->home->rel_file('mct.conf'),
    default => {
      db => 'postgresql://localhost/mct_test',
    },
  });

  $app->helper('model.conference'   => sub { MCT::Model::Conference->new(pg => shift->app->pg, @_) });
  $app->helper('model.user'         => sub { MCT::Model::User->new(pg => shift->app->pg, @_) });
  $app->helper('model.presentation' => sub { MCT::Model::Presentation->new(pg => shift->app->pg, @_) });

  $app->_migrate_database;
  $app->_ensure_conference;
  $app->_routes;
}

sub _ensure_conference {
  my $app = shift;
  my $conference = $app->config('conference');
  my $model = $app->model->conference(%$conference);

  $app->defaults(conference => $model->load->save($conference));
}

sub _migrate_database {
  my $app = shift;
  my $migrations = $app->migrations;
  $app->pg->migrations->migrate(0) if $ENV{MCT_RESET_DATABASE}; # useful while developing
  $app->pg->migrations->migrate;
}

sub _routes {
  my $app = shift;
  my $r = $app->routes;

  $r->any('/')->to('home#landing_page')->name('landing_page');
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

Glen Hinkle C<tempire@cpan.org>

Jan Henning Thorsen, E<lt>jhthorsen@cpan.orgE<gt>

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2014 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
