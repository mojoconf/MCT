use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

plan skip_all => 'set TEST_ONLINE'
  unless $ENV{MCT_DATABASE_DSN} = $ENV{TEST_ONLINE};

my $t = Test::Mojo->new('MCT');

my $app = $t->app;

$app->migrations->migrate(0);
$app->migrations->migrate;

$app->model->conference(
  identifier => 'mojoconf2015',
  country => 'NO',
  name => 'MojoConf 2015',
)->save;
$app->model->user(
  username => 'jberger',
  name => 'Joel Berger',
)->save;

my $err;
my $presentation = $app->model->presentation(
  author => 'jberger',
  conference => 'mojoconf2015',
  title => 'My Talk',
  url_name => 'my-talk',
)->save;
ok $presentation->id, 'id';
is $presentation->author, 'jberger', 'author';
ok !$err or diag $err;

$presentation = $app->model->presentation(conference => 'mojoconf2015', url_name => 'my-talk')->load;
ok !$err or diag $err;
is $presentation->author, 'jberger';
is $presentation->author_name, 'Joel Berger';
is $presentation->conference, 'mojoconf2015';
is $presentation->title, 'My Talk';
is $presentation->url_name, 'my-talk';

$presentation->title('Another Title')->save;
$presentation = $app->model->presentation(conference => 'mojoconf2015', url_name => 'my-talk')->load;

is_deeply $presentation->TO_JSON, {
  id => $presentation->id,
  abstract => '',
  author => 'jberger',
  author_name => 'Joel Berger',
  conference => 'mojoconf2015',
  title => 'Another Title',
  url_name => 'my-talk',
};

$app->migrations->migrate(0);

done_testing;

