package MCT::Plugin::Auth;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app) = @_;
  my $connect;

  $connect->{providers} = $app->config('providers') || $app->config('oauth2');
  $connect->{connector} = \&_connect_user;

  if ($ENV{MCT_MOCK}) {
    $app->log->warn('[MCT_MOCK=1] Mocking interfaces.');
    $connect->{providers}{mocked}{key} = 'mocked';
    $connect->{default_provider} = 'mocked';
  }
  else {
    $connect->{default_provider} = 'github';
  }

  $app->plugin(Connect => $connect);
  $app->connect->ua->server->app($app);
}

sub _connect_user {
  my ($c, $err, $oauth2_user) = @_;
  my $identity;

  return $c->render('user/connect_failed', error => $err) if $err;
  return $c->delay(
    sub {
      my ($delay) = @_;
      $identity = $c->model->identity;
      $identity->provider($oauth2_user->provider);
      $identity->token($oauth2_user->token);
      $identity->uid($oauth2_user->id);
      $identity->user($oauth2_user, $delay->begin);
    },
    sub {
      my ($delay, $err, $model_user) = @_;
      return $c->reply->exception($err) if $err;
      $c->session(username => $model_user->username);
      return $c->reply->connected($model_user->id);
    },
  );
}

1;
