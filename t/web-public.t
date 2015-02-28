use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

my $t = Test::Mojo->new('MCT');

$t->get_ok('/conduct')->status_is(200);
$t->get_ok('/travel')->status_is(200);
$t->get_ok('/announce')->status_is(200);

done_testing;
