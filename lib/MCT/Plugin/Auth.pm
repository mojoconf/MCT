package MCT::Plugin::Auth;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app) = @_;
  my $config = $app->config('oauth2');
  my $r = $app->routes;

  $app->helper('reply.connect' => \&_connect);
  $app->helper('reply.connect_failed' => \&_connect_failed);

  $app->routes->add_shortcut(authorized => sub {
    my $r = shift;

    return $r->under(sub {
      my $c = shift;
      return 1 if $c->session('uid');
      return $c->reply->connect;
      return undef;
    });
  });

  $app->defaults(oauth2_provider => 'github');

  $app->plugin(
    OAuth2 => {
      github => {
        key => $config->{github}{key} || 'REQUIRED',
        secret => $config->{github}{secret} || 'REQUIRED',
        scope => 'user',
      },
      mocked => {
        key => $ENV{MCT_MOCK} ? 'mocked' : '',
        scope => 'user',
      },
    }
  );
}

sub _connect {
  my $c = shift;
  my $identity = $c->model->identity(provider => $c->stash('oauth2_provider'));
  my $path = $c->req->url->path;

  if ($c->session('uid')) {
    return $c->redirect_to($c->flash('original_path') || 'profile');
  }
  if ($path !~ m!^/connect!) {
    $c->flash(original_path => $path);
  }

  $c->delay(
    sub {
      my ($delay) = @_;
      my $args = { redirect_uri => $c->url_for('connect')->userinfo(undef)->to_abs };
      $c->oauth2->get_token($identity->provider, $args, $delay->begin);
    },
    sub {
      my ($delay, $err, $token) = @_;
      return $c->render('user/connect_failed', error => $err) unless $token;
      return $c->github->token($token)->user($delay->begin);
    },
    sub {
      my ($delay, $err, $data) = @_;
      return $c->reply->exception($err || 'Unknown error from github.com') unless $data;
      return $identity->token($c->github->token)->uid($data->{id})->user($data, $delay->begin);
    },
    sub {
      my ($delay, $err, $user) = @_;
      return $c->reply->exception($err) if $err;
      return $c->session(uid => $user->id)->redirect_to($c->flash('original_path') || 'profile');
    }
  );
}

sub _connect_failed {
  my ($c, $err) = @_;

  $c->app->log->error($err || 'Connect failed');
  $c->reply->connect;
}

1;
