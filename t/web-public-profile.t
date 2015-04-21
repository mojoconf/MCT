use t::Helper;

my $t = t::Helper->t;
my $conference = $t->app->model->conference(name => 'xyz', country => 'NO')->save(sub {});

$t->get_ok('/user/connect?code=42')->status_is(302);
my $user = $t->app->model->user(username => 'john_gh')->load->bio('I do my little turn on the catwalk.')->save;
$t->get_ok('/xyz/user/logout')->status_is(302)->header_is(Location => '/xyz');

$t->get_ok('/xyz/user/whatever/profile')->status_is(404);
$t->get_ok('/xyz/user/john_gh/profile')->status_is(200)
  ->text_is('title', 'xyz - Profile')
  ->text_is('dl dt:nth-of-type(1)', 'Github profile')
  ->text_is('dl dd:nth-of-type(1) a[href="https://github.com/john_gh"]', 'john_gh')
  ->text_is('dl dt:nth-of-type(2)', 'Home page')
  ->text_is('dl dd:nth-of-type(2) a[href="http://mojolicio.us"]', 'http://mojolicio.us')
  ->element_exists_not('dl dd:nth-of-type(3)')
  ->text_is('div.bio p', 'I do my little turn on the catwalk.');

$conference->grant_role('john_gh', 'admin');
$t->get_ok('/user/connect?code=42')->status_is(302);
$t->get_ok('/xyz/user/john_gh/profile')->status_is(200)
  ->text_is('title', 'xyz - Profile')
  ->text_is('dl dt:nth-of-type(1)', 'Github profile')
  ->text_is('dl dd:nth-of-type(1) a[href="https://github.com/john_gh"]', 'john_gh')
  ->text_is('dl dt:nth-of-type(2)', 'Home page')
  ->text_is('dl dd:nth-of-type(2) a[href="http://mojolicio.us"]', 'http://mojolicio.us')
  ->text_is('dl dd:nth-of-type(3) a[href="mailto:john@example.com"]', 'john@example.com')
  ->text_is('dl dd:nth-of-type(4)', 'Gotham City')
  ->text_is('dl dd:nth-of-type(5)', '-')
  ->text_is('dl dd:nth-of-type(6)', '-')
  ->text_is('dl dd:nth-of-type(7)', '-')
  ->text_is('dl dd:nth-of-type(8)', '-')
  ->element_exists_not('dl dd:nth-of-type(9)')
  ->text_is('div.bio p', 'I do my little turn on the catwalk.');

done_testing;
