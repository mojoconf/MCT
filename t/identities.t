use t::Helper;

my $t = t::Helper->t;

my ($err, $user);
my $data = {
  login => 'mitch',
  email => 'mitch@eventbrite.com',
  name => 'Mich Doe',
};

{
  # rollback
  no warnings qw( redefine once );
  local *MCT::Model::Identity::save = sub { die 'ROLLBACK' };
  my $identity = $t->app->model->identity(provider => 'github', token => 's3cret', uid => 42);
  my $user;
  $identity->user($data, sub { (undef, $err, $user) = @_ });
  like $err, qr{ROLLBACK}, 'died';
  ok !$identity->in_storage, 'identity rollback';
  ok !$user->in_storage, 'user rollback';
}

# try to copy logic from MCT::Controller::User::_connect_with_oauth_provider()
my $identity = $t->app->model->identity(provider => 'github');
ok !$identity->in_storage, 'identity.not_in_storage';
ok !$user, 'no user';

$identity->token('s3cret');
$identity->uid('whatever:123456789')->user($data, sub { (undef, $err, $user) = @_ });
ok !$err, 'no error' or diag $err;
ok $identity->in_storage, 'identity.in_storage';
ok $user->in_storage, 'user.in_storage';
is $user->email, 'mitch@eventbrite.com', 'user.email';
is $user->username, 'mitch@eventbrite.com', 'user.username';
ok $user->id, 'user.id';

done_testing;
