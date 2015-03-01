use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'set TEST_ONLINE'
  unless $ENV{MCT_DATABASE_DSN} = $ENV{TEST_ONLINE};

$ENV{MCT_MOCK} = 1;
my $t = Test::Mojo->new('MCT');

$t->get_ok('/logout')->status_is(200);

# redirected to eventbrite connect page
$t->get_ok('/profile')->status_is(302);
my $url = Mojo::URL->new($t->tx->res->headers->location);
is $url->query->param('client_id'), 'mocked', 'oauth.client_id';
like $url->query->param('redirect_uri'), qr{/connect$}, 'oauth.redirect_uri';
like $url, qr{^/mocked/oauth/authorize}, 'oauth.base_path';

# connect with eventbrite
$t->get_ok($url)->status_is(200)->element_exists('a');
$t->get_ok($t->tx->res->dom->at('a')->{href})->status_is(302)->header_is(Location => '/profile');

# access profile page
$t->get_ok('/profile')->status_is(200)
  ->element_exists('input[name="name"][value="John Doe"]')
  ->element_exists('input[name="email"][value="john@example.com"]');

# logged out
$t->get_ok('/logout')->status_is(200)->content_like(qr{Logged out});
$t->get_ok('/profile')->status_is(302);

$t->app->migrations->migrate(0);

done_testing;
