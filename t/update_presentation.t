use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

plan skip_all => 'set TEST_ONLINE'
  unless $ENV{MCT_DATABASE_DSN} = $ENV{TEST_ONLINE};

$ENV{MCT_MOCK} = 1;

my $t = Test::Mojo->new('MCT');

my $app = $t->app;

$app->migrations->migrate(0);
$app->migrations->migrate;

$t->get_ok('/user/connect', form => {code => 42})->status_is(302);

my $pres = {
  title => 'My Title',
  subtitle => 'Some Subtitle',
  abstract => 'My content here',
};
my $location = '/2015/presentations/my_title';
$t->post_ok('/2015/presentations', form => $pres)
  ->status_is(302)
  ->header_is('Location' => $location);

$t->get_ok($location)
  ->status_is(200)
  ->text_is('title' => 'Mojoconf 2015 - My Title')
  ->text_is('#title' => 'My Title')
  ->text_is('#subtitle' => 'My Subtitle')
  ->text_is('#author' => 'Presented by: John Doe')
  ->text_is('#abstract' => 'My content here');

$t->get_ok("$location/edit")
  ->status_is(200)
  ->text_is('title' => 'Mojoconf 2015 - Edit: My Title')
  ->text_is('input[name="abstract"]' => 'My content here');

my $dom = $t->tx->res->dom;
is $dom->at('input[name="title"]')->{value}, 'My Title';
is $dom->at('input[name="subtitle"]')->{value}, 'My Subtitle';

# add the id and make a change
$pres->{id} = $dom->at('input[name="id"]')->{value};
$pres->{abstract} = 'New content here';

$t->post_ok('/2015/presentations', form => $pres)
  ->status_is(302)
  ->header_is('Location' => $location);

$t->get_ok($location)
  ->status_is(200)
  ->text_is('title' => 'Mojoconf 2015 - My Title')
  ->text_is('#title' => 'My Title')
  ->text_is('#subtitle' => 'My Subtitle')
  ->text_is('#author' => 'Presented by: John Doe')
  ->text_is('#abstract' => 'New content here');

#TODO add test for changing title and thus location

done_testing;

