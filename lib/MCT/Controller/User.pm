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
    return $c->stash(is_admin => 0)->render('user/profile');
  }

  $c->delay(
    sub { $c->stash('conference')->has_role({id => $user->id}, 'admin', shift->begin); },
    sub {
      my ($delay, $err, $is_admin) = @_;
      $c->stash(is_admin => $is_admin);
      $user->load($delay->begin);
    },
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

sub public_profile {
  my $c = shift;
  my $user = $c->model->user(username => $c->stash('username'));
  my @is_admin;

  $c->stash(user => $user);

  if (my $uid = $c->session('uid')) {
    push @is_admin, sub { $c->stash('conference')->has_role({id => $uid}, 'admin', shift->begin); };
  }

  $c->delay(
    @is_admin,
    sub {
      my ($delay, $err, $is_admin) = @_;
      $c->stash(is_admin => $is_admin);
      $user->load($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->reply->not_found unless $user->id;
      return $c->respond_to(
        json => {json => {TODO => 1}},
        any => {}
      );
    },
  );
}

sub purchases {
  my $c = shift;
  my $user = $c->model->user(id => $c->session('uid'));

  $c->stash(user => $user);
  $c->delay(
    sub { $user->load(shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $user->purchases($delay->begin);
    },
    sub {
      my ($delay, $err, $purchases) = @_;
      die $err if $err;
      $c->render('user/purchases', purchases => $purchases);
    }
  );
}

1;
