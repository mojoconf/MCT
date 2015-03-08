use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

plan skip_all => 'set TEST_ONLINE'
  unless $ENV{MCT_DATABASE_DSN} = $ENV{TEST_ONLINE};

my $t = Test::Mojo->new('MCT');

my $app = $t->app;

$app->migrations->migrate(0);
$app->migrations->migrate;

my $ident = '';
my $err;
my $conference = $app->model->conference(
  name => 'MojoConf 2015',
  country => 'US',
  tagline => 'All the Mojo you can Conf',
)->save(sub { (undef, $err, undef) = @_ });
ok !$err or diag $err;

ok $conference->in_storage;
is $conference->name, 'MojoConf 2015';

$conference = $app->model->conference(identifier => 'mojoconf-2015')->load;
ok !$err or diag $err;
is $conference->name, 'MojoConf 2015';
is $conference->tagline, 'All the Mojo you can Conf';
ok $conference->id;

$conference->save({ tagline => 'Confing all the Mojo' });
$app->model->conference(identifier => 'mojoconf-2015')->load(sub { (undef, $err) = @_ });
ok !$err or diag $err;
is_deeply $conference->TO_JSON, {
  id => $conference->id,
  identifier => 'mojoconf-2015',
  name => 'MojoConf 2015',
  tagline => 'Confing all the Mojo',
};

$app->migrations->migrate(0);

done_testing;

