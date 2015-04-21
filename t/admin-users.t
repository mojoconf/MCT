use t::Helper;

my $t = t::Helper->t;

my $conference = $t->app->model->conference(name => 'Devops')->save;

$t->get_ok('/user/connect', form => {code => 42})->status_is(302);

$t->get_ok('/devops/user/admin/users')->status_is(302);

$conference->grant_role('john_gh', 'admin');
$t->get_ok('/devops/user/admin/users')
  ->status_is(200)
  ->$_test_table([
    [
      ['a[href="/devops/user/john_gh/profile"]', 'John Doe'],
      ['a[href="mailto:john@example.com"]', 'john@example.com'],
    ]
  ]);

done_testing;
