use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

plan skip_all => 'set TEST_ONLINE'
  unless my $db = $ENV{TEST_ONLINE};

my $t = Test::Mojo->new('MCT');
$t->app->config->{db} = $db;
$t->app->migrations->migrate(0);
$t->app->migrations->migrate;

my ($err, $user);
my $data = {
  emails => [ { email => 'mitch@eventbrite.com', verified => 1, primary => 1 } ],
  id => 'whatever:123456789',
  name => 'John Doe',
  first_name => 'John',
  last_name => 'Doe',
};

{
  # rollback
  no warnings 'redefine';
  local *MCT::Model::Identity::save = sub { die 'ROLLBACK' };
  my $identity = $t->app->model->identity(provider => 'eventbrite', token => 's3cret', uid => 42);
  my $user;
  $identity->user($data, sub { (undef, $err, $user) = @_ });
  like $err, qr{ROLLBACK}, 'died';
  ok !$identity->in_storage, 'identity rollback';
  ok !$user->in_storage, 'user rollback';
}

# try to copy logic from MCT::Controller::User::_connect_with_oauth_provider()
my $identity = $t->app->model->identity(provider => 'eventbrite');
ok !$identity->in_storage, 'identity.not_in_storage';
ok !$user, 'no user';

$identity->token('s3cret');
$identity->uid($data->{id})->user($data, sub { (undef, $err, $user) = @_ });
ok !$err, 'no error' or diag $err;
ok $identity->in_storage, 'identity.in_storage';
ok $user->in_storage, 'user.in_storage';
is $user->email, 'mitch@eventbrite.com', 'user.email';
is $user->username, 'mitch@eventbrite.com', 'user.username';
ok $user->id, 'user.id';

$t->app->migrations->migrate(0);

done_testing;
