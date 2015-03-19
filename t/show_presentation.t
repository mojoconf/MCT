use t::Helper;

my $t = t::Helper->t;
my $app = $t->app;

my $conf = $app->model->conference(name => 'Test For Show Presentation', country => 'GB')->save;
$app->model->user(username => 'jberger', name => 'Joel Berger')->save;

my $presentation = $app->model->presentation(
  author => 'jberger',
  conference => $conf->{identifier},
  title => 'My Talk',
  url_name => 'my-talk',
  abstract => 'What I will be talking about',
)->save;

$t->get_ok("/$conf->{identifier}/presentations/my-talk")
  ->status_is(200)
  ->text_is('title' => 'Test For Show Presentation - My Talk')
  ->text_is('#title' => 'My Talk')
  ->text_is('#author' => 'Presented by: Joel Berger')
  ->text_is('#abstract' => 'What I will be talking about');

done_testing;

