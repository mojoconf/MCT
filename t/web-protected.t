use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

my $t = Test::Mojo->new('MCT');

$t->get_ok('/profile')->status_is(302);
my $url = Mojo::URL->new($t->tx->res->headers->location);
is $url->query->param('client_id'), 'REQUIRED', 'client_id';
like $url->query->param('redirect_uri'), qr{/profile$}, 'redirect_uri';
like $url, qr{^https://www\.eventbrite\.com/oauth/authorize}, 'base path';

done_testing;
