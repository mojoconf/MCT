package MCT::Controller::User;

use Mojo::Base 'Mojolicious::Controller';

sub profile {
  my $c = shift;
  my $user = $c->model->user(username => $c->session('username'));

  return $c->redirect_to('login') unless $user->username;
  return $c->delay(
    sub {
      my ($delay) = @_;
      $user->load($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      return $c->reply->exception($err) if $err; # TODO: Better error handling
      return $c->redirect_to('register') unless $user->id; # TODO: Is this even possible?
      return $c->respond_to(
        json => {json => $user},
        any => sub {shift->render(user => $user)}
      );
    },
  );
}

sub register {
  my $c = shift;
  my $user = $c->model->user;
  my $validation = $c->validation;

  $validation->required('email')->like(qr{.\@.}); # poor mans regex
  $validation->optional('username')->like(qr/^[a-z][a-z0-9]{2,}$/i); # at least three characters
  $validation->has_error and return $c->render;

  $c->delay(
    sub {
      my ($delay) = @_;
      $user->save($validation->output, $delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      return $c->reply->exception($err) if $err; # TODO: Better error handling
      return $c->session(username => $user->username)->redirect_to('profile');
    },
  );
}

1;
