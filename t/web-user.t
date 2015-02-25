use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'set TEST_ONLINE'
  unless my $db = $ENV{TEST_ONLINE};

my $t = Test::Mojo->new('MCT');
$t->app->config->{db} = $db;
$t->app->migrations->migrate(0)->migrate;

$t->get_ok('/profile')->status_is(302)->header_is(Location => '/login');
$t->get_ok('/register')->status_is(200)->element_exists('form[action="/register"][method="post"]');

$t->post_ok('/register', form => { email => 'bruce@wayneenterprice.com', password => 's3cret' })->status_is(302);
$t->get_ok($t->tx->res->headers->location)->status_is(200)->element_exists('input[name="email"][value="bruce@wayneenterprice.com"]');

done_testing;
