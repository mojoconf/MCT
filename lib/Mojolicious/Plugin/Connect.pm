package Mojolicious::Plugin::Connect;

=head1 NAME

Mojolicious::Plugin::Connect - Mojolicious plugin for connecting third party users to your application

=head1 VERSION

0.01

=head1 SYNOPSIS

  use Mojolicious::Lite;

  plugin Connect => {
    connector => sub {
      my ($c, $err, $user) = @_;

      $c->delay(
        sub {
          my ($delay) = @_;
          return $c->reply->exception($err) if $err; # handle errors
          $your_db->store($user, $delay->begin); # store $user
        },
        sub {
          my ($delay, $err) = @_;
          return $c->reply->exception($err) if $err;
          return $c->reply->connected(123); # redirect user if data was saved
        },
      );
    },
    providers => { # Mojolicious::Plugin::Oauth2 config
      github => {
        key    => "public-key",
        secret => "private-secret",
      },
    },
  };

  # protected by github OAuth2
  app->connect->authorized_route(app->routes)->get("/user/profile" => sub {
    my $c = shift;
    # ...
  });

=head1 DESCRIPTION

L<Mojolicious::Plugin::Connect> is a L<Mojolicious::Plugin>, which allow you
to connect and fetch user information from a OAuth2 provider.

See also L<Mojolicious::Plugin::Oauth2>.

=head2 Supported OAuth2 providers

This plugin only support a fixed set of providers, because the code to fetch
the L</User> data is not generic.

Please submit a L<pull request|https://github.com/jhthorsen/mojo-connect/pulls>
if you have code for more providers.

=over 4

=item * Eventbrite

=item * Github

=item * Google

=back

=head2 User

The C<$user> referred to in this documentation is a hash-ref holding a
normalized version of data from a OAuth2 provider.

TODO: Document the structure.

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util;
use Mojo::UserAgent;
use Mojolicious::Plugin::Connect::User;

our $VERSION = '0.01';

# useful when testing.
# Note: This might go away without warning.
our $ERR = '';
our $USER = {
  avatar_url => 'https://avatars.githubusercontent.com/u/45729?v=3',
  email => 'john@example.com',
  gravatar_id => '',
  id => '42',
  location => 'Gotham City',
  login => 'john_gh',
  name => 'John Doe',
  blog => 'http://mojolicio.us',
};

=head1 HELPERS

=head2 connect

  $self = $c->connect;

Returns the plugin instance.

=head2 reply.connect

Will send you to the third party OAuth2 provider, unless session has
"uid" set.

=head2 reply.connected

  $c->reply->connected($uid);

Call this after a user is successfully connected. The result is a redirect
back to where the user was before starting the connect process.

=head1 SESSION DATA

=head2 connected_with

  $str = $c->session("connected_with");

Holds the name of the provider connecting/connected with. See also
L</default_provider>.

=head2 uid

  $str = $c->session("uid");

You can set this value to anything. The important part is that the user will
not be redirected to third party OAuth2 provider, if it contains a true value.

=head1 ATTRIBUTES

=head2 connect_route

  $str = $self->connect_route;

Name of the route that the will be used as C<redirect_uri> to
L<Mojolicious::Plugin::Oauth2>. Default value is "user.connect".

A default route will be added, unless a route is already
L<defined|Mojolicious::Routes::Route/find>:

  $r->get("/user/connect")->to(sub { shift->reply->connect })->name($self->connect_route);

=head2 default_provider

  $str = $self->default_provider;

Name of the default provider. This value is used unless...

=over 4

=item 1.

C<connected_with> is set in L<session|Mojolicious::Controller/session>.

=item 2.

C<connect_with> is available from L<param|Mojolicious::Controller/param>.
The C<param()> value is checked against the C<providers> data structure
given as C<%config> to this plugin. (See L</SYNOPSIS>)

=back

=head2 default_redirect_route

  $str = $self->default_redirect_route;

L</reply.connected> will use this value if it does not know the last page the
user visited.

Default value is "user.profile".

=head2 connector

  $code = $self->connector;

Holds a code ref that connects the L<user|Mojolicious::Plugin::Connect::User>
with your application.

See L</SYNOPSIS> for example.

=cut

has connect_route => '';
has default_redirect_route => '';
has default_provider => '';
has connector => sub { die 'connector is required attribute' };
has ua => sub { Mojo::UserAgent->new->max_redirects(3); };

=head1 METHODS

=head2 authorized_route

  $r2 = $app->connect->authorized_route($r1);

Used to make a protected route.

=cut

sub authorized_route {
  my ($self, $r, $cb) = @_;

  return $r->under->to(cb => sub {
    my $c = shift;
    return 1 if $c->session('uid');
    $self->_connect($c);
    return;
  });
}

=head2 register

  $app->plugin(Connect => \%config);

Will register this plugin in your L<Mojolicious> application. C<%config> will
be used to define the L</ATTRIBUTES>.

=cut

sub register {
  my ($self, $app, $config) = @_;
  my $oauth2_config = $self->_oauth2_config($config->{providers});

  $self->connect_route($config->{connect_route}                   // 'user.connect');
  $self->default_redirect_route($config->{default_redirect_route} // 'user.profile');
  $self->connector($config->{connector}) if $config->{connector};
  $self->default_provider($config->{default_provider}) if $config->{default_provider};
  $self->_add_connect_route($app) unless $self->connect_route =~ m!/!;

  $oauth2_config->{fix_get_token} = 1; # Required for OAuth2 1.51
  $app->plugin(OAuth2 => $oauth2_config);
  $app->helper(connect         => sub {$self});
  $app->helper('reply.connect' => sub { $self->_connect(@_) });
  $app->helper('reply.connected' => sub { $self->_connected(@_) });
}

sub _add_connect_route {
  my ($self, $app) = @_;

  unless ($app->routes->find($self->connect_route)) {
    $app->routes->get('/user/connect')->to(cb => sub { shift->reply->connect })->name($self->connect_route);
  }
}

sub _connect {
  my ($self, $c) = @_;
  my $connector    = $self->connector;
  my $path         = $c->req->url->path;
  my $connect_path = $c->url_for($self->connect_route)->path;
  my ($args, $provider);

  # already connected
  if ($c->session('uid')) {
    return $c->redirect_to(delete $c->session->{'connect.rdr'} || $self->default_redirect_route);
  }

  # save redirect path before being redirected
  if ($path =~ m!^$connect_path!) {
    $path = $c->req->headers->referrer;
  }
  if ($path and $path !~ m!^$connect_path! and $path !~ m!^/mocked/!) {
    $c->session('connect.rdr' => $path);
  }

  if ((!$c->param('code') and !$c->param('error')) or !$c->session('connected_with')) {
    $c->session->{connected_with} = do {
      my $name = $c->param('connect_with');
      ($name and $self->{allowed}{$name}) ? $name : $self->default_provider;
    };
  }

  $c->delay(
    sub {
      my ($delay) = @_;
      $provider = $c->session('connected_with');
      $args     = {%{$c->stash('connect_args')||{}}};                # do not modify input
      $args->{redirect_uri} ||= $c->url_for($self->connect_route)->userinfo(undef)->to_abs;
      $c->oauth2->get_token($provider, $args, $delay->begin);
    },
    sub {
      my ($delay, $err, $data) = @_;
      return $c->$connector($err, {}) unless $data->{access_token};
      $args->{token} = $data->{access_token} // '';
      $args->{provider} = $provider;
      delete $args->{redirect_uri};

      # TODO: Factor out these methods to different modules
      $self->${ \"_get_user_from_$provider" }($args, $delay->begin);
    },
    sub {
      my ($delay, $err, $user) = @_;
      $c->$connector($err, $user);
    }
  );
}

sub _connected {
  my ($self, $c, $uid) = @_;

  $c->session(uid => $uid || die 'Usage: $c->reply->connected($uid)');
  $c->redirect_to(delete $c->session->{'connect.rdr'} || $self->default_redirect_route);
}

sub _get_user_from_eventbrite {
  my ($self, $args, $cb) = @_;
  my $user = Mojolicious::Plugin::Connect::User->new($args);
  my %headers = (Authorization => "Bearer $args->{token}");

  Mojo::IOLoop->delay(
    sub {
      $self->ua->get("https://www.eventbriteapi.com/v3/users/me", \%headers, shift->begin);
    },
    sub {
      my ($delay, $tx) = @_;
      my $err = $tx->res->error;
      return $self->$cb($err->{message}, undef) if $err;
      return $self->$cb('', $user->data($tx->res->json));
    },
  );
}

sub _get_user_from_github {
  my ($self, $args, $cb) = @_;
  my $user = Mojolicious::Plugin::Connect::User->new($args);
  my %headers = (Authorization => "token $args->{token}");

  Mojo::IOLoop->delay(
    sub {
      $self->ua->get('https://api.github.com/user', \%headers, shift->begin);
    },
    sub {
      my ($delay, $tx) = @_;
      my $err = $tx->res->error;
      return $self->$cb($err->{message}, {}) if $err;
      $user->data($tx->res->json);
      return $self->$cb('', $user) if $user->email;
      $self->ua->get('https://api.github.com/user/emails', \%headers, $delay->begin);
    },
    sub {
      my ($delay, $tx) = @_;
      $user->data->{emails} = $tx->res->json;
      return $self->$cb('', $user);
    },
  );
}

sub _get_user_from_google {
  my ($self, $args, $cb) = @_;
  my $user = Mojolicious::Plugin::Connect::User->new($args);
  my $url = Mojo::URL->new('https://www.googleapis.com/plus/v1/people/me');

  Mojo::IOLoop->delay(
    sub {
      $url->query(key => $args->{token});
      $self->ua->get($url, shift->begin);
    },
    sub {
      my ($delay, $tx) = @_;
      my $err = $tx->res->error;
      return $self->$cb($err->{message}, {}) if $err;
      return $self->$cb('', $user->data($tx->res->json));
    },
  );
}

sub _get_user_from_mocked {
  my ($self, $args, $cb) = @_;
  my $user = Mojolicious::Plugin::Connect::User->new($args);
  $self->$cb($ERR, $user->data($USER));
}

sub _oauth2_config {
  my ($self, $config) = @_;

  for my $name (sort keys %$config) {
    $self->{allowed}{$name} = 1;
    $self->{default_provider} ||= $name;
    $config->{$name}{scope} //= 'user:email';
  }

  return $config;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
