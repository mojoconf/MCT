use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

plan skip_all => 'set TEST_ONLINE'
  unless my $db = $ENV{TEST_ONLINE};

my $t = Test::Mojo->new('MCT');

my $app = $t->app;
$app->config->{db} = $db;

$app->migrations->migrate;

my ($err, $data);
$app->model->user->create({
  name => 'Joel Berger',
  username => 'jberger',
  email => 'joel.a.berger@gmail.com',
}, sub { (undef, $err, undef) = @_ });
ok !$err or diag $err;

$app->model->user->get('jberger', sub { (undef, $err, $data) = @_ });
$data = $data->hash;
ok !$err or diag $err;
is $data->{name}, 'Joel Berger';
is $data->{username}, 'jberger';
is $data->{email}, 'joel.a.berger@gmail.com';

$app->model->user->update('jberger', {email => 'jberger@nospam.org'}, sub { (undef, $err, undef) = @_ });
ok !$err or diag $err;

$app->model->user->get('jberger', sub { (undef, $err, $data) = @_ });
$data = $data->hash;
ok !$err or diag $err;
is $data->{name}, 'Joel Berger';
is $data->{email}, 'jberger@nospam.org';

$app->migrations->migrate(0);

done_testing;

