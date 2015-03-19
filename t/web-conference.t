use t::Helper;

my $t = t::Helper->t;

$t->app->model->conference(
  name => 'Mojoconf 2015',
  tagline => 'All the Mojo you can conf',
  country => 'DK',
)->save(sub {});

$t->get_ok('/mojoconf-2015')->status_is(200)->text_is('title', 'Mojoconf 2015 - Home');
$t->get_ok('/mojoconf-2015.json')->status_is(200)->json_is('/name', 'Mojoconf 2015')->json_is('/identifier', 'mojoconf-2015');

done_testing;
