use t::Helper;

my $t = t::Helper->t;
my $app = $t->app;

my $conf = $app->model->conference(name => 'Test For Show Presentation', country => 'GB')->save;
$app->model->user(username => 'jberger', name => 'Joel Berger')->save;

my $presentation = $app->model->presentation(
  author => 'jberger',
  conference => $conf->{identifier},
  title => 'My Talk',
  identifier => 'my-talk',
  description => "# Cool talk\nMy content here\n\nAnother paragraph\n\n",
)->save;

$t->get_ok("/$conf->{identifier}/presentations/my-talk")
  ->status_is(200)
  ->text_is('title' => 'Test For Show Presentation - My Talk')
  ->text_is('h2' => 'My Talk')
  ->text_is('.author a' => 'Joel Berger')
  ->text_is('h4' => 'Cool talk')
  ->text_like('.abstract p:nth-of-type(1)', qr{My content here})
  ->text_like('.abstract p:nth-of-type(2)', qr{Another paragraph});

done_testing;

