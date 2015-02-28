use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'set TEST_ONLINE'
  unless my $db = $ENV{TEST_ONLINE};

$ENV{MCT_MOCK} = 1;
my $t = Test::Mojo->new('MCT');

$t->app->config->{db} = $db;

$t->get_ok('/connect')->status_is(200)->text_is('a[href^="https://www.eventbrite.com/oauth/authorize"]', 'Login');
$t->get_ok('/logout')->status_is(302);
$t->get_ok($t->tx->res->headers->location)->content_unlike(qr{Logged out});

$t->get_ok('/profile')->status_is(302)->header_is(Location => '/profile');
$t->get_ok('/profile')->status_is(200)
  ->element_exists('input[name="name"][value="John Doe"]')
  ->element_exists('input[name="email"][value="john@example.com"]');

$t->get_ok('/logout')->status_is(302);
$t->get_ok($t->tx->res->headers->location)->content_like(qr{Logged out});

$t->app->migrations->migrate(0);

done_testing;
