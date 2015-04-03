use t::Helper;

my $t = t::Helper->t;
my $conference = $t->app->model->conference(name => 'tpc', country => 'SE')->save(sub {});

$t->get_ok('/user/connect?code=42')->status_is(302);
$t->get_ok('/tpc/user/profile')->status_is(200)->text_is('title', 'tpc - Profile')
  ->element_exists('a[href="/tpc/user/presentations"]')
  ->element_exists('a[href="/tpc/user/purchases"]')
  ->element_exists_not('a[href="/tpc/user/admin/users"]')
  ->element_exists('a[href="/tpc/user/logout"]')
  ->element_exists('img[src^="https://avatars.githubusercontent.com/u/45729"]')
  ->element_exists('input[name="name"][value="John Doe"]')
  ->element_exists('input[name="email"][value="john@example.com"]')
  ->element_exists('input[name="address"][value="Gotham City"]')
  ->element_exists('input[name="zip"][value=""]')
  ->element_exists('input[name="city"][value=""]')
  ->element_exists('select[name="country"]')
  ->element_exists('select[name="t_shirt_size"]')
  ->element_exists('input[name="web_page"][value="http://mojolicio.us"]')
  ->text_is('textarea[name="bio"]', '');

my %profile = (
  name => 'Bruce Wayne',
  email => 'bruce@wayneindustries.com',
  address => 'Batcave',
  zip => '123',
  city => 'Gotham City',
  country => 'US',
  t_shirt_size => 'M',
  web_page => 'http://en.wikipedia.org/wiki/Wayne_Enterprises',
  avatar_url => 'https://gravatar.com/avatar/b850d96978b5b07e2e523b81db30c26b',
  bio => 'Perl is my oyster.',
);

$t->post_ok('/tpc/user/profile', form => \%profile)->status_is(200)
  ->element_exists('img[src^="https://gravatar.com/avatar/b850d96978b5b07e2e523b81db30c26b"]')
  ->element_exists('input[name="name"][value="Bruce Wayne"]')
  ->element_exists('input[name="email"][value="bruce@wayneindustries.com"]')
  ->element_exists('input[name="address"][value="Batcave"]')
  ->element_exists('input[name="zip"][value="123"]')
  ->element_exists('input[name="city"][value="Gotham City"]')
  ->element_exists('select[name="country"] option[value="US"][selected]')
  ->element_exists('select[name="t_shirt_size"] option[value="M"][selected]')
  ->element_exists('input[name="web_page"][value="http://en.wikipedia.org/wiki/Wayne_Enterprises"]')
  ->text_is('textarea[name="bio"]', 'Perl is my oyster.');

$t->post_ok('/tpc/user/profile', form => {})->status_is(200);

# partial update
$t->post_ok('/tpc/user/profile', form => {t_shirt_size => 'S', email => 'partial@update.com', name => 'Mr.X'})->status_is(200)
  ->element_exists('img[src^="https://gravatar.com/avatar/b850d96978b5b07e2e523b81db30c26b"]')
  ->element_exists('input[name="city"][value="Gotham City"]')
  ->element_exists('select[name="t_shirt_size"] option[value="S"][selected]');

$conference->grant_role('john_gh', 'admin');
$t->get_ok('/tpc/user/profile')->element_exists('a[href="/tpc/user/admin/users"]');

done_testing;
