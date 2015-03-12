package MCT::Controller::User;

use Mojo::Base 'Mojolicious::Controller';

sub logout {
  my $c = shift;
  delete $c->session->{$_} for qw( connected_with uid username );
  $c->render('user/logout');
}

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
  my $validation = $c->validation;
  my $update = $c->req->method eq 'POST';

  $c->stash(user => $user);
  $validation->input->{username} = $c->session('username') unless $validation->param('username');

  if ($update and $user->validate($validation)->has_error) {
    return $c->render('user/profile');
  }

  $c->delay(
    sub { $user->load(shift->begin) },
    sub {
      my ($delay, $err) = @_;
      return $user->save($validation->output, $delay->begin) if $update;
      return $delay->pass('');
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $c->session(username => $user->username) if $update;
      return $c->reply->exception('No user id? That is weird.') unless $user->id;
      return $c->respond_to(
        json => {json => $user},
        any => {template => 'user/profile'},
      );
    },
  );
}

1;
