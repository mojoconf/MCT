package MCT::Controller::User;

use Mojo::Base 'Mojolicious::Controller';

sub profile {
  my $c = shift;
  my $user = $c->model->user(id => $c->session('uid'));

  unless ($user->id) {
    return $c->_connect_with_oauth_provider;
  }

  $c->delay(
    sub {
      my ($delay) = @_;
      $user->load($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->render('user/connect') unless $user->id; # TODO: Is this even possible?
      return $c->respond_to(
        json => {json => $user},
        any => {user => $user},
      );
    },
  );
}

sub _connect_with_oauth_provider {
  my $c = shift;
  my $identity = $c->model->identity(provider => 'eventbrite');

  $c->delay(
    sub {
      my ($delay) = @_;
      $c->get_token($identity->provider, $delay->begin);
    },
    sub {
      my ($delay, $token, $tx) = @_;
      return $c->reply->exception('Unable to fetch token.') unless $token;
      $identity->token($token);
      $c->eventbrite->token($token)->user($delay->begin);
    },
    sub {
      my ($delay, $err, $data) = @_;
      return $c->reply->exception($err || 'Unknown error from eventbrite.com') unless $data;
      return $identity->uid($data->{id})->user($data, $delay->begin);
    },
    sub {
      my ($delay, $err, $user) = @_;
      return $c->reply->exception($err) if $err;
      return $c->session(uid => $user->id)->redirect_to('profile');
    }
  );
}

sub logout {
  my $c = shift;
  $c->flash(logged_out => defined delete $c->session->{uid})->redirect_to('connect');
}

1;
