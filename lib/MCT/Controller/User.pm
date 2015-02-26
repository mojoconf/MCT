package MCT::Controller::User;

use Mojo::Base 'Mojolicious::Controller';

sub login {
  my $c = shift;
  my $validation = $c->validation;
  my $user = $c->model->user(id => $c->session('uid'));
  my $update = $c->req->method eq 'POST';

  if (!$user->id) {
    return $c->redirect_to('login');
  }
  if ($update and $user->validate($c->validation)->has_error) {
    return;
  }

  $c->delay(
    sub {
      my ($delay) = @_;
      return $user->save($validation->output, $delay->begin) if $update;
      return $user->load($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      return $c->reply->exception($err) if $err; # TODO: Better error handling
      return $c->session(uid => 0)->redirect_to('register') unless $user->id; # TODO: Is this even possible?
      return $c->respond_to(
        json => {json => $user},
        any => sub {shift->render(user => $user)}
      );
    },
  );

}

sub profile {
  my $c = shift;
  my $validation = $c->validation;
  my $user = $c->model->user(id => $c->session('uid'));
  my $update = $c->req->method eq 'POST';

  if (!$user->id) {
    return $c->redirect_to('login');
  }
  if ($update and $user->validate($c->validation)->has_error) {
    return;
  }

  $c->delay(
    sub {
      my ($delay) = @_;
      return $user->save($validation->output, $delay->begin) if $update;
      return $user->load($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      return $c->reply->exception($err) if $err; # TODO: Better error handling
      return $c->session(uid => 0)->redirect_to('register') unless $user->id; # TODO: Is this even possible?
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

  if ($c->session('uid')) {
    return $c->redirect_to('profile');
  }
  if ($user->validate($validation)->has_error) {
    return;
  }

  $c->delay(
    sub {
      my ($delay) = @_;
      $user->save($validation->output, $delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      return $c->render(error => $err) if $err; # TODO: Better error handling
      return $c->session(uid => $user->id)->redirect_to('profile');
    },
  );
}

1;
