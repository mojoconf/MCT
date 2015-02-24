use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

plan skip_all => 'set TEST_ONLINE'
  unless my $db = $ENV{TEST_ONLINE};

my $t = Test::Mojo->new('MCT');

my $app = $t->app;
$app->config->{db} = $db;

$app->migrations->migrate(0);
$app->migrations->migrate;

my $ident = '';
my ($err, $data);
$app->model->conference->create({
  identifier => 'mojoconf2015',
  name => 'MojoConf 2015',
  tagline => 'All the Mojo you can Conf',
}, sub { (undef, $err, undef) = @_ });
ok !$err or diag $err;

$app->model->conference->get('mojoconf2015', sub { (undef, $err, $data) = @_ });
$data = $data->hash;
ok !$err or diag $err;
is $data->{name}, 'MojoConf 2015';
is $data->{tagline}, 'All the Mojo you can Conf';

$app->model->conference->update('mojoconf2015', {tagline => 'Confing all the Mojo'}, sub { (undef, $err, undef) = @_ });
ok !$err or diag $err;

$app->model->conference->get('mojoconf2015', sub { (undef, $err, $data) = @_ });
$data = $data->hash;
ok !$err or diag $err;
is $data->{name}, 'MojoConf 2015';
is $data->{tagline}, 'Confing all the Mojo';

$app->migrations->migrate(0);

done_testing;

