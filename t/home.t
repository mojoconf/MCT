use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'set TEST_ONLINE'
  unless my $db = $ENV{TEST_ONLINE};

my $t = Test::Mojo->new('MCT');
$t->app->config->{db} = $db;

$t->get_ok('/')->status_is(200)->text_is('title', 'Mojoconf 2015');

done_testing;
