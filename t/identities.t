use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

plan skip_all => 'set TEST_ONLINE'
  unless my $db = $ENV{TEST_ONLINE};

my $t = Test::Mojo->new('MCT');
$t->app->config->{db} = $db;
$t->app->migrations->migrate(0);
$t->app->migrations->migrate;

Mojo::IOLoop->timer(1 => sub { Mojo::IOLoop->stop }); # guard

my ($err, $user);
my $data = {
  emails => [ { email => 'mitch@eventbrite.com', verified => 1, primary => 1 } ],
  id => 'whatever:123456789',
  name => 'John Doe',
  first_name => 'John',
  last_name => 'Doe',
};

# try to copy logic from MCT::Controller::User::_connect_with_oauth_provider()
my $identity = $t->app->model->identity(provider => 'eventbrite');
$identity->token('s3cret');
ok !$identity->in_storage, 'identity.not_in_storage';
ok !$user, 'no user';
$identity->uid($data->{id})->user($data, sub { (undef, $err, $user) = @_; Mojo::IOLoop->stop });
Mojo::IOLoop->start;
ok !$err, 'no error' or diag $err;
ok $identity->in_storage, 'identity.in_storage';
ok $user->in_storage, 'user.in_storage';
is $user->email, 'mitch@eventbrite.com', 'user.email';
is $user->username, 'mitch-eventbrite-com', 'user.username';
ok $user->id, 'user.id';

$t->app->migrations->migrate(0);

done_testing;
