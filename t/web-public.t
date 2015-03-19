use t::Helper;

my $t = t::Helper->t;

$t->app->model->conference(
  name => 'Mojoconf 2015',
  identifier => '2015',
  tagline => 'All the Mojo you can conf',
  country => 'RU',
)->save(sub {});

$t->get_ok('/')->status_is(302)->header_is(Location => '/2015');
$t->get_ok('/2015/conduct')->status_is(200);
$t->get_ok('/2015/travel')->status_is(200);

done_testing;
