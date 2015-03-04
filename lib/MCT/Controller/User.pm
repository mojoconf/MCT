package MCT::Controller::User;

use Mojo::Base 'Mojolicious::Controller';

# it's important for the security of OAuth2 to have a fixed redirect_uri
sub connect {
  shift->reply->connect;
}

sub profile {
  my $c = shift;
  my $user = $c->model->user(id => $c->session('uid'));

  $c->delay(
    sub {
      my ($delay) = @_;
      return $delay->pass if $c->req->method ne 'POST';
      return $user->validate($c->validation, $delay->begin);
    },
    sub {
      my ($delay, $err, $validation) = @_;
      return $c->render(error => $err) if $err or $validation and $validation->has_error;
      return $user->save($validation->output) if $validation;
      return $user->load($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->reply->connect_failed('Did not think this was possible.') unless $user->id;
      return $c->respond_to(
        json => {json => $user},
        any => {user => $user},
      );
    },
  );
}

sub logout {
  my $c = shift;
  delete $c->session->{uid};
  $c->render;
}

1;
