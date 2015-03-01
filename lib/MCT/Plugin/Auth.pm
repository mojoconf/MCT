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

  $app->defaults(oauth2_provider => 'eventbrite');

  $app->plugin(
    OAuth2 => {
      eventbrite => {
        authorize_url => 'https://www.eventbrite.com/oauth/authorize',
        token_url => 'https://www.eventbrite.com/oauth/token',
        key => $config->{eventbrite}{key} || 'REQUIRED',
        secret => $config->{eventbrite}{secret} || 'REQUIRED',
        scope => $config->{eventbrite}{scope} || '',
      },
      mocked => {
        authorize_url => '/mocked/oauth/authorize',
        token_url => '/mocked/oauth/token',
        key => 'mocked',
        secret => 'mocked-secret',
        scope => $config->{eventbrite}{scope} || '',
      },
    }
  );
}

sub _connect {
  my $c = shift;
  my $identity = $c->model->identity(provider => $c->stash('oauth2_provider'));

  if ($c->session('uid')) {
    return $c->redirect_to($c->flash('original_path') || 'profile');
  }
  if (!$c->param('code')) { # code is set when returned from oauth2_provider
    $c->flash(original_path => $c->req->url->path);
  }

  $c->delay(
    sub {
      my ($delay) = @_;
      $c->get_token($identity->provider, redirect_uri => $c->url_for('connect')->userinfo(undef)->to_abs, $delay->begin);
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
      $c->session(uid => $user->id);
      $c->redirect_to($c->flash('original_path') || 'profile');
    }
  );
}

sub _connect_failed {
  my ($c, $err) = @_;

  $c->app->log->error($err || 'Connect failed');
  $c->reply->connect;
}

1;
