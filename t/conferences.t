use t::Helper;

my $t = t::Helper->t;
my $app = $t->app;

my $ident = '';
my $err;
my $conference = $app->model->conference(
  name => 'MojoConf 2015',
  country => 'US',
  tagline => 'All the Mojo you can Conf',
)->save(sub { (undef, $err, undef) = @_ });
ok !$err or diag $err;

ok $conference->in_storage;
is $conference->name, 'MojoConf 2015';

$conference = $app->model->conference(identifier => 'mojoconf-2015')->load;
ok !$err or diag $err;
is $conference->name, 'MojoConf 2015';
is $conference->tagline, 'All the Mojo you can Conf';
ok $conference->id;

$conference->save({ tagline => 'Confing all the Mojo' });
$app->model->conference(identifier => 'mojoconf-2015')->load(sub { (undef, $err) = @_ });
ok !$err or diag $err;
is_deeply $conference->TO_JSON, {
  id => $conference->id,
  identifier => 'mojoconf-2015',
  name => 'MojoConf 2015',
  tagline => 'Confing all the Mojo',
};

done_testing;
