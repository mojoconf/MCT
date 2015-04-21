use t::Helper;

my $t = t::Helper->t;

my $app = $t->app;

$app->model->conference(
  identifier => 'mojoconf2015',
  country => 'NO',
  name => 'MojoConf 2015',
)->save;
$app->model->user(
  username => 'jberger',
  name => 'Joel Berger',
)->save;

my $err;
my $presentation = $app->model->presentation(
  author => 'jberger',
  conference => 'mojoconf2015',
  title => 'My Talk',
  identifier => 'my-talk',
)->save;
ok $presentation->id, 'id';
is $presentation->author, 'jberger', 'author';
ok !$err or diag $err;

$presentation = $app->model->presentation(conference => 'mojoconf2015', identifier => 'my-talk')->load;
ok !$err or diag $err;
is $presentation->author, 'jberger';
is $presentation->author_name, 'Joel Berger';
is $presentation->conference, 'mojoconf2015';
is $presentation->title, 'My Talk';
is $presentation->identifier, 'my-talk';

$presentation->title('Another Title')->save;
$presentation = $app->model->presentation(conference => 'mojoconf2015', identifier => 'my-talk')->load;

is $presentation->status, 'TENTATIVE';
$presentation->change_status('CONFIRMED', sub {});
is $presentation->status, 'CONFIRMED';

is_deeply $presentation->TO_JSON, {
  id => $presentation->id,
  description => '',
  author => 'jberger',
  author_name => 'Joel Berger',
  conference => 'mojoconf2015',
  title => 'Another Title',
  identifier => 'my-talk',
};

done_testing;

