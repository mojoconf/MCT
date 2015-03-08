package MCT::Controller::Conference;

use Mojo::Base 'Mojolicious::Controller';

sub landing_page {
  my $c = shift;

  $c->respond_to(
    json => {json => $c->stash('conference')},
    any => sub {shift->render}
  );
}

1;
