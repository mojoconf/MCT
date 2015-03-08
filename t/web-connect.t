use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'set TEST_ONLINE'
  unless $ENV{MCT_DATABASE_DSN} = $ENV{TEST_ONLINE};

$ENV{MCT_MOCK} = 1;
my $t = Test::Mojo->new('MCT');

$t->app->migrations->migrate(0)->migrate;
$t->app->model->conference(name => 'Testing Connect', country => 'GB')->save(sub {});

$t->get_ok('/user/logout')->status_is(200);

# redirected to github connect page
$t->get_ok('/testing-connect/profile')->status_is(302);
my $url = Mojo::URL->new($t->tx->res->headers->location);
is $url->query->param('client_id'), 'mocked', 'oauth.client_id';
like $url->query->param('redirect_uri'), qr{/connect$}, 'oauth.redirect_uri';
like $url, qr{^/mocked/oauth/authorize}, 'oauth.base_path';

# fail to connect with github
$t->get_ok($url)->status_is(200)->element_exists('a');

$url = Mojo::URL->new($t->tx->res->dom->at('a')->{href})->query(error => 'access_denied');
$t->get_ok($url)->status_is(200)->text_is('title', 'Unable to connect with Github');

# connect with github
$url->query->remove('error');
$url->query->param(code => 42);
$t->get_ok($url)->status_is(302);

{
  local $TODO = 'Need fixin';
  $t->header_is(Location => '/testing-connect/profile');
}

# access profile page
$t->get_ok('/testing-connect/profile')->status_is(200);

# logged out
$t->get_ok('/user/logout')->status_is(200)->content_like(qr{Logged out});
$t->get_ok('/testing-connect/profile')->status_is(302);

done_testing;
