use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'set TEST_ONLINE'
  unless $ENV{MCT_DATABASE_DSN} = $ENV{TEST_ONLINE};

my $t = Test::Mojo->new('MCT');

$t->get_ok('/')->status_is(200)->text_is('title', 'Mojoconf 2015 - Home');
$t->get_ok('/.json')->status_is(200)->json_is('/name', 'Mojoconf 2015')->json_is('/identifier', 'mojoconf-2015');

$t->app->migrations->migrate(0);

done_testing;
