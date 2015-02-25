package MCT;

use Mojo::Base 'Mojolicious';

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

  $r->get('/')->to('home#landing_page')->name('landing_page');
  $r->get('/register')->to(template => 'user/register')->name('register');
  $r->post('/register')->to('user#register');
  $r->any('/profile')->to('user#profile')->name('profile');
  $r->get('/login')->to(template => 'user/login')->name('login');
}

1;

