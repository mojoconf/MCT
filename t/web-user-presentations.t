use t::Helper;

plan skip_all => 'set TEST_ONLINE'
  unless $ENV{MCT_DATABASE_DSN} = $ENV{TEST_ONLINE};

$ENV{MCT_MOCK} = 1;

my $t = Test::Mojo->new('MCT');
my $app = $t->app;

$app->migrations->migrate(0)->migrate;
$t->app->model->conference(name => 'All the presentations')->save;
$t->app->model->conference(name => 'Other conference')->save;

$t->get_ok('/user/connect', form => {code => 42})->status_is(302);
$t->get_ok('/all-the-presentations/user/presentations')->status_is(200)
  ->text_is('section:nth-of-child(2) > h3', 'No presentations')
  ->element_exists_not('table');

my $pres = { title => 'Extremely cool talk about users', abstract => 'My content here' };
$t->post_ok('/all-the-presentations/user/presentations', form => $pres)->status_is(302);

$pres->{title} = 'Another cool talk';
$t->post_ok('/other-conference/user/presentations', form => $pres)->status_is(302);

$pres->{title} = 'Yet a talk';
$t->post_ok('/other-conference/user/presentations', form => $pres)->status_is(302);

$t->get_ok('/all-the-presentations/user/presentations')->status_is(200)
  ->text_is('section:nth-of-child(2) > h3', 'Your presentations')
  ->$_test_table([
    [
      'Other conference',
      ['a[href="/other-conference/presentations/another-cool-talk"]', 'Another cool talk' ],
    ],
    [
      'Other conference',
      ['a[href="/other-conference/presentations/yet-a-talk"]', 'Yet a talk' ],
    ],
    [
      'All the presentations',
      ['a[href="/all-the-presentations/presentations/extremely-cool-talk-about-users"]', 'Extremely cool talk about users' ],
    ],
  ]);

$t->get_ok('/all-the-presentations/user/logout')->status_is(200);
$t->get_ok('/all-the-presentations/user/presentations')->status_is(302);

done_testing;
