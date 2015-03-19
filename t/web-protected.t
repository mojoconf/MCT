use t::Helper;

$ENV{MOJO_MODE} = 'test';
$ENV{MCT_MOCK} = 0;
my $t = t::Helper->t;

$t->app->model->conference(name => 'Whatever Conf', country => 'NP')->save(sub {});

$t->get_ok('/whatever-conf/user/profile')->status_is(302);
my $url = Mojo::URL->new($t->tx->res->headers->location);
is $url->query->param('client_id'), 'some-public-key', 'client_id';
is $url->query->param('state'), 'whatever-conf', 'state';
like $url->query->param('redirect_uri'), qr{/connect$}, 'redirect_uri';
like $url, qr{^https://github\.com/login/oauth/authorize}, 'base path';

$t->get_ok('/user/connect?error=whatever')->status_is(200)
  ->text_is('section a[href="/"]', 'Try again');

$t->get_ok('/user/connect?state=whatever-conf&error=whatever')->status_is(200)
  ->text_is('section a[href="/whatever-conf/user/profile"]', 'Try again');

done_testing;
