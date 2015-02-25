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
  $app->pg->migrations->from_file($app->config->{schema});
}

sub startup {
  my $app = shift;

  $app->plugin(Config => {
    file => $app->home->rel_file('mct.conf'),
    default => {
      db => 'postgresql://localhost/mct_test',
      schema => $app->home->rel_file('mct.sql'),
    },
  });

  $app->helper('model.conference'   => sub { MCT::Model::Conference->new(pg => shift->app->pg) });
  $app->helper('model.user'         => sub { MCT::Model::User->new(pg => shift->app->pg) });
  $app->helper('model.presentation' => sub { MCT::Model::Presentation->new(pg => shift->app->pg) });

  $app->helper(conference_name    => sub { shift->app->conference->name });
  $app->helper(conference_tagline => sub { shift->app->conference->tagline });

  my $r = $app->routes;
  $r->any('/')->to('home#home');
}

1;

