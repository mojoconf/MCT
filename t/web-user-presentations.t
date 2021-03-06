use t::Helper;

my $t = t::Helper->t;
my $app = $t->app;

$t->app->model->conference(name => 'All the presentations')->save;
$t->app->model->conference(name => 'Other conference')->save;

$t->get_ok('/user/connect', form => {code => 42})->status_is(302);
$t->get_ok('/all-the-presentations/user/presentations')->status_is(200)
  ->text_is('section:nth-of-child(1) > h3', 'No presentations')
  ->element_exists_not('table');

my $pres = { title => 'Extremely cool talk about users', description => "# Cool talk\nMy content here\nAnother paragraph\n\n" };
$t->post_ok('/all-the-presentations/user/presentations', form => $pres)->status_is(302);

$pres->{title} = 'Another cool talk';
$t->post_ok('/other-conference/user/presentations', form => $pres)->status_is(302);

$pres->{title} = 'Yet a talk';
$t->post_ok('/other-conference/user/presentations', form => $pres)->status_is(302);

$t->get_ok('/all-the-presentations/user/presentations')->status_is(200)
  ->text_is('section:nth-of-child(1) > h3', 'Your presentations')
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

$t->get_ok('/all-the-presentations/user/logout')->status_is(302);
$t->get_ok('/all-the-presentations/user/presentations')->status_is(302);

done_testing;
