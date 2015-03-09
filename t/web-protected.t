use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'set TEST_ONLINE'
  unless $ENV{MCT_DATABASE_DSN} = $ENV{TEST_ONLINE};

$ENV{MOJO_MODE} = 'test';
my $t = Test::Mojo->new('MCT');

$t->app->migrations->migrate(0)->migrate;
$t->app->model->conference(name => 'Whatever Conf', country => 'NP')->save(sub {});

$t->get_ok('/whatever-conf/user/profile')->status_is(302);
my $url = Mojo::URL->new($t->tx->res->headers->location);
is $url->query->param('client_id'), 'some-public-key', 'client_id';
like $url->query->param('redirect_uri'), qr{/connect$}, 'redirect_uri';
like $url, qr{^https://github\.com/login/oauth/authorize}, 'base path';

done_testing;
