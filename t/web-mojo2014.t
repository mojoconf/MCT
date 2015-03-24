use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'set TEST_ONLINE' unless $ENV{MCT_DATABASE_DSN} = $ENV{TEST_ONLINE};
plan skip_all => 'set TEST_ACT=1' unless $ENV{TEST_ACT};

my $t = Test::Mojo->new('MCT');
my $host_port;

$t->get_ok('/');
$host_port = $t->tx->req->url->host_port;

$t->get_ok('/mojo2014/schedule?day=2014-05-24')->status_is(302)->header_is(Location => '/2014/schedule?day=2014-05-24');

$t->get_ok('/2014')
  ->status_is(200)
  ->element_exists(qq([href="http://$host_port/2014/css/mojoconf.css"]))
  ->element_exists(qq([src="http://$host_port/2014/js/jquery.js"]));

$t->get_ok('/2014/schedule?day=2014-05-24')
  ->status_is(200)
  ->element_exists(qq(a[href="http://$host_port/2014/event/1519"]));

$t->get_ok('/2014/css/mojoconf.css')->status_is(200);

done_testing;
