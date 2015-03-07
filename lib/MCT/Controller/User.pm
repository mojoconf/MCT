package MCT::Controller::User;

use Mojo::Base 'Mojolicious::Controller';

sub profile {
  my $c = shift;
  my $user = $c->model->user(id => $c->session('uid'));

  $c->delay(
    sub {
      my ($delay) = @_;
      $user->load($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->reply->exception('No user id? That is weird.') unless $user->id;
      return $c->respond_to(
        json => {json => $user},
        any => {user => $user},
      );
    },
  );
}

1;
