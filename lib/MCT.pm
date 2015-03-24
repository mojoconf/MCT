package MCT;

use Mojo::Base 'Mojolicious';

our $VERSION = '0.01';

use Mojo::Pg;
use MCT::Model;
use MCT::Model::Countries;

has pg => sub { Mojo::Pg->new(shift->config->{db}) };

sub migrations {
  my $app = shift;
  $app->pg->migrations->from_file($app->home->rel_file('mct.sql'));
}

sub startup {
  my $app = shift;

  $app->plugin('Config' => file => $ENV{MOJO_CONFIG} || $app->home->rel_file('mct.conf'));

  $app->_setup_database;
  $app->_setup_secrets;
  $app->_setup_stripe;
  $app->_setup_validation;

  $app->helper('model.db'           => sub { $_[0]->stash->{'mct.db'} ||= $_[0]->app->pg->db });
  $app->helper('model.conference'   => sub { MCT::Model->new_object(Conference => db => shift->model->db, @_) });
  $app->helper('model.identity'     => sub { MCT::Model->new_object(Identity => db => shift->model->db, @_) });
  $app->helper('model.presentation' => sub { MCT::Model->new_object(Presentation => db => shift->model->db, @_) });
  $app->helper('model.user'         => sub { MCT::Model->new_object(User => db => shift->model->db, @_) });
  $app->helper('form_row'           => \&_form_row);

  $app->plugin('MCT::Plugin::Auth');
  $app->plugin('AssetPack');
  $app->_assets;
  $app->_routes;
  $app->migrations->migrate unless $ENV{MCT_SKIP_MIGRATION};
}

sub _assets {
  my $app = shift;

  $app->asset->preprocessors->add(
    css => sub {
      my ($assetpack, $text, $file) = @_;

      if ($file =~ /font.*awesome/) {
        $$text =~ s!url\(["']../([^']+)["']\)!url(https://maxcdn.bootstrapcdn.com/font-awesome/4.3.0/$1)!g;
      }
    },
  );

  $app->asset('mojoconf.js' => (
    'http://code.jquery.com/jquery-1.11.2.min.js',
    'https://raw.githubusercontent.com/stripe/jquery.payment/master/lib/jquery.payment.js',
    '/js/mct-stripe.js',
  ));

  $app->asset('mojoconf.css' => (
    'https://fonts.googleapis.com/css?family=Oswald:400,300,700',
    'https://fonts.googleapis.com/css?family=PT+Sans+Narrow',
    'https://maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css',
    '/sass/mct.scss',
  ));
}

sub _form_row {
  my ($c, $name, $model, $label, $field) = @_;

  return $c->tag(div => class => 'form-row', sub {
    return join('',
      $c->tag(label => for => "form_$name", sub { $label }),
      $field || $c->text_field($name, $model ? $model->$name : '', id => "form_$name"),
    );
  });
}

sub _routes {
  my $app = shift;

  $app->routes->get('/')->to('conference#latest_conference')->name('index');
  $app->routes->post('/')->to('conference#create')->name('conference.create');

  # back compat
  $app->plugin('MCT::Plugin::ACT' => { url => 'http://act.yapc.eu/mojo2014/' });

  my $conf = $app->routes->under('/:cid')->to('conference#load');
  $conf->get('/')->to('conference#landing_page')->name('landing_page');
  $conf->get('/register')->to('conference#register')->name('user.register');
  $conf->get('/user/logout')->to('user#logout')->name('user.logout');
  $conf->get('/:page')->to('conference#page')->name('conference.page');

  my $user = $app->connect->authorized_route($conf->any('/user'));
  $user->any('/profile')->to('user#profile')->name('user.profile');
  $user->get('/presentations')->to('user#presentations')->name('user.presentations');
  $user->post('/presentations')->to('presentation#store')->name('presentation.save');
  $user->post('/purchase')->to('conference#purchase')->name('product.purchase');

  my $presentations = $conf->any('/presentations')->to('presentation#');
  $presentations->get('/')->to('#list')->name('presentations'); # TODO

  my $presentation = $presentations->any('/:url_name');
  $presentation->get('/')->to('#show')->name('presentation');
  $presentation->get('/edit')->to('#edit')->name('presentation.edit');
}

sub _setup_database {
  my $app = shift;
  my $migrations;

  unless ($app->config->{db} ||= $ENV{MCT_DATABASE_DSN}) {
    my $db = sprintf 'postgresql://%s@/mct_%s', (getpwuid $<)[0] || 'postgresql', $app->mode;
    $app->config->{db} = $db;
    $app->log->warn("Using default database '$db'. (Neither MCT_DATABASE_DSN or config file was set up)");
  }
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

sub _setup_stripe {
  my $app = shift;
  my $stripe = $app->config('stripe');

  $stripe->{auto_capture} = 0;
  $stripe->{mocked} //= $ENV{MCT_MOCK};
  $app->plugin('StripePayment' => $stripe);
}

sub _setup_validation {
  my $app = shift;
  $app->validator->add_check(country => sub {
    my ($validation, $name, $value) = @_;
    MCT::Model::Countries->name_from_code($value) ? undef : ['country'];
  });
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
