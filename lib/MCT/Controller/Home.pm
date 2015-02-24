package MCT::Controller::Home;

use Mojo::Base 'Mojolicious::Controller';

sub home {
  my $c = shift;
  $c->render('home');
}

1;

