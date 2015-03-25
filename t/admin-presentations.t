use t::Helper;

my $t = t::Helper->t;

my $conference = $t->app->model->conference(name => 'Devops')->save;

$t->get_ok('/user/connect', form => {code => 42})->status_is(302);
$t->post_ok('/devops/user/presentations', form => {title => 't1', abstract => 'a1'})->status_is(302);

$t->get_ok('/devops/user/admin/presentations')->status_is(302);

$conference->grant_role('john_gh', 'admin');
$t->get_ok('/devops/user/admin/presentations')
  ->status_is(200)
  ->$_test_table([
    [
      ['a[href="/devops/presentations/t1"]', 't1'],
      '20',
      'waiting',
    ]
  ]);

done_testing;
