use t::Helper;

my $t = t::Helper->t;

my $conference = $t->app->model->conference(name => 'Mortal Kombat')->save;
my $fight = $conference->product(name => 'Ultimate fight', description => "# The ultimate fight", price => 66600)->save;
my %event = (
  name => 'New fight',
  currency => 'NOK',
  price => 9999,
  n_of => 100,
  description => 'New description',
);

$t->get_ok('/mortal-kombat/events/1')
  ->status_is(200)
  ->element_exists('a[href="/mortal-kombat/register"]')
  ->element_exists_not('a[href="/mortal-kombat/events/1/edit"]')
  ->text_is('h2', 'The ultimate fight');

# cannot edit before logged in
$t->get_ok('/mortal-kombat/events/1/edit')->status_is(302);
$t->post_ok('/mortal-kombat/events/1/edit', form => \%event)->status_is(302);

# cannot edit even if logged in
$t->get_ok('/user/connect?code=42')->status_is(302);
$t->get_ok('/mortal-kombat/events/1/edit')->status_is(302);
$t->post_ok('/mortal-kombat/events/1/edit', form => \%event)->status_is(302);

# can edit after admin role
$conference->grant_role('john_gh', 'admin');

$t->get_ok('/mortal-kombat/events/1')
  ->status_is(200)
  ->element_exists('a[href="/mortal-kombat/events/1/edit"]');

$t->get_ok('/mortal-kombat/events/1/edit')
  ->status_is(200)
  ->element_exists('form[action="/mortal-kombat/events/1/edit"][method="POST"]')
  ->element_exists('form input[name="name"][value="Ultimate fight"]')
  ->element_exists('form input[name="currency"][value="USD"]')
  ->element_exists('form input[name="price"][value="66600"]')
  ->element_exists('form input[name="n_of"][value="1"]')
  ->element_exists('form textarea[name="description"]')
  ->element_exists('button[name="view"][value="1"]')
  ->element_exists_not('.saved');

$t->post_ok('/mortal-kombat/events/1/edit', form => \%event)
  ->status_is(200)
  ->element_exists('form[action="/mortal-kombat/events/1/edit"][method="POST"]')
  ->element_exists('form input[name="name"][value="New fight"]')
  ->element_exists('form input[name="currency"][value="NOK"]')
  ->element_exists('form input[name="price"][value="9999"]')
  ->element_exists('form input[name="n_of"][value="100"]')
  ->element_exists('form textarea[name="description"]')
  ->element_exists('button[name="view"][value="1"]')
  ->element_exists('.saved');

$event{view} = 1;
$t->post_ok('/mortal-kombat/events/1/edit', form => \%event)->status_is(302)->header_is(Location => '/mortal-kombat/events/1');

done_testing;
