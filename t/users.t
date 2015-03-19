use t::Helper;

my $t = t::Helper->t;
my $app = $t->app;

my $err;
my $user = $app->model->user(
  name => 'Joel Berger',
  username => 'jberger',
  email => 'joel.a.berger@gmail.com',
);

is $user->in_storage, 0, 'in_storage=0';
$user->save(sub { (undef, $err) = @_ });
is $user->in_storage, 1, 'in_storage=1';
is $user->email, 'joel.a.berger@gmail.com', 'email';
is $user->name, 'Joel Berger', 'name';
is $user->username, 'jberger', 'username';
ok !$err or diag $err;

$user = $app->model->user(username => 'jberger')->load(sub { (undef, $err) = @_ });
ok !$err or diag $err;
is $user->in_storage, 1, 'in_storage=1';
is $user->name, 'Joel Berger';
is $user->username, 'jberger';
is $user->email, 'joel.a.berger@gmail.com';

$user->email('jberger@nospam.org');
is $user->save, $user, 'save sync';
ok !$err or diag $err;

$user = $app->model->user(username => 'jberger')->load;
ok !$err or diag $err;

is_deeply $user->TO_JSON, {
  id => $user->id,
  name => 'Joel Berger',
  email => 'jberger@nospam.org',
  username => 'jberger',
};

done_testing;

