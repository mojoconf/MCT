package MCT::Controller::Event;

use Mojo::Base 'Mojolicious::Controller';

sub show {
  my $c = shift;
  my $p = $c->model->conference->product(id => $c->param('id'));

  # TODO: Should be a proper event object?

  $c->delay(
    sub { $p->load(shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $p->name ? $c->render('event/show', event => $p) : $c->reply->not_found;
    },
  );
}

1;
