use t::Helper;

my $t = t::Helper->t;

$t->get_ok('/user/connect', form => {code => 42})->status_is(302);

$t->app->model->conference(
  name => 'Mojoconf 2015',
  identifier => '2015',
  tagline => 'All the Mojo you can conf',
)->save;

$t->get_ok('/2015/user/presentations')
  ->status_is(200)
  ->text_is('title' => 'Mojoconf 2015 - My Presentations')
  ->element_exists('form[action="/2015/user/presentations"][method="post"]')
  ->element_exists('form input[name="title"]')
  ->element_exists('form textarea[name="description"]');

# test validation failure
$t->post_ok('/2015/user/presentations', form => {})
  ->status_is(200)
  ->text_is('title' => 'Mojoconf 2015 - Submit a presentation')
  ->element_exists('input.field-with-error[name="title"]')
  ->element_exists('textarea.field-with-error[name="description"]');

my $pres = {
  title => 'My Title',
  description => 'My content here',
};
my $location = '/2015/presentations/my-title';
$t->post_ok('/2015/user/presentations', form => $pres)
  ->status_is(302)
  ->header_is('Location' => $location);

$t->get_ok($location)
  ->status_is(200)
  ->text_is('title' => 'Mojoconf 2015 - My Title')
  ->text_is('h2' => 'My Title')
  ->text_is('.author a' => 'John Doe')
  ->text_is('a[href="/2015/presentations/1/edit"]', 'Edit')
  ->text_like('.abstract p' => qr{My content here});

$t->get_ok("/2015/presentations/1/edit")
  ->status_is(200)
  ->text_is('title' => 'Mojoconf 2015 - My Title')
  ->element_exists('form[method="POST"][action="/2015/presentations/1/edit"]')
  ->element_exists('input[name="title"][value="My Title"]')
  ->text_is('textarea[name="description"]' => 'My content here')
  ->element_exists('button[name="view"][value="1"]')
  ->element_exists_not('.saved')
  ;

# add the id and make a change
$pres->{id} = $t->tx->res->dom->at('input[name="id"]')->{value};
$pres->{description} = 'New content here';

$t->post_ok('/2015/presentations/1/edit', form => $pres)
  ->status_is(200)
  ->text_is('title' => 'Mojoconf 2015 - My Title')
  ->element_exists('input[name="title"][value="My Title"]')
  ->text_is('textarea[name="description"]' => 'New content here')
  ->element_exists('.saved');

$pres->{description} = 'Some evil <script src="/evil/location.js"></script>';
$t->post_ok('/2015/presentations/1/edit', form => $pres)->status_is(200);
$t->get_ok("/2015/presentations/my-title")
  ->status_is(200)
  ->element_exists_not('script[src="/evil/location.js"]');

# change the title (and thus identifier)
$pres->{title} = 'Some New Title';
$pres->{view} = 1;
my $new_location = '/2015/presentations/some-new-title';

$t->post_ok('/2015/presentations/1/edit', form => $pres)
  ->status_is(302)
  ->header_is('Location' => $new_location);

$t->get_ok($location)->status_is(404);

$t->get_ok($new_location)
  ->status_is(200)
  ->text_is('title' => 'Mojoconf 2015 - Some New Title')
  ->text_is('h2' => 'Some New Title')
  ->text_is('.author a' => 'John Doe')
  ->text_is('.abstract p' => 'Some evil <script src="/evil/location.js"></script>');

$t->reset_session;

# attemp to view edit page without permission
$t->get_ok("/2015/presentations/1/edit")
  ->status_is(401)
  ->content_is('Not authorized');

# attempt to update the presentation without permission
my %bad = (%$pres, description => 'This is bad');
$t->post_ok('/2015/presentations/1/edit', form => \%bad)->status_is(401);

$t->get_ok($new_location)
  ->status_is(200)
  ->text_is('.abstract p' => $pres->{description}, 'description not changed');

done_testing;
