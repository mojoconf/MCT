package MCT::Controller::User;

use Mojo::Base 'Mojolicious::Controller';

sub presentations {
  my $c = shift;
  my $user = $c->model->user(id => $c->session('uid'));
  $c->stash(user => $user);
  $c->delay(
    sub { $user->load(shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $user->presentations($delay->begin);
    },
    sub {
      my ($delay, $err, $presentations) = @_;
      die $err if $err;
      $c->render('user/presentations', presentations => $presentations);
    }
  );
}

sub profile {
  my $c = shift;
  my $user = $c->model->user(id => $c->session('uid'));
  my $update = $c->req->method eq 'POST';

  $c->stash(user => $user);

  if ($update and $user->validate($c->validation)->has_error) {
    return;
  }

  $c->delay(
    sub {
      my ($delay) = @_;
      return $user->save($c->validation->output, $delay->begin) if $update;
      return $user->load($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->reply->exception('No user id? That is weird.') unless $user->id;
      return $c->respond_to(
        json => {json => $user},
        any => {},
      );
    },
  );
}

1;
