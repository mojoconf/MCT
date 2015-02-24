use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

plan skip_all => 'set TEST_ONLINE'
  unless my $db = $ENV{TEST_ONLINE};

my $t = Test::Mojo->new('MCT');

my $app = $t->app;
$app->config->{db} = $db;

$app->migrations->migrate(0);
$app->migrations->migrate;

$app->model->conference->create({
  identifier => 'mojoconf2015',
  name => 'MojoConf 2015',
});
$app->model->user->create({
  username => 'jberger',
  name => 'Joel Berger',
});

my ($err, $data);
$app->model->presentation->create({
  conference => 'mojoconf2015',
  username => 'jberger',
  title => 'My Talk',
  url_name => 'my-talk',
}, sub { (undef, $err, undef) = @_ });
ok !$err or diag $err;

$app->model->presentation->get('mojoconf2015', 'my-talk', sub { (undef, $err, $data) = @_ });
ok !$err or diag $err;
$data = $data->hash;
is $data->{title}, 'My Talk';
is $data->{author}, 'Joel Berger';
is $data->{url_title}, 'my-talk';

done_testing;
__END__

$app->model->user->update('mojoconf2015', 'my-talk', {title => 'Another Title'}, sub { (undef, $err, undef) = @_ });
ok !$err or diag $err;

$app->model->user->get('mojoconf2015', 'my-talk', sub { (undef, $err, $data) = @_ });
$data = $data->hash;
ok !$err or diag $err;
is $data->{title}, 'Another Title';
is $data->{author}, 'Joel Berger';

$app->migrations->migrate(0);

done_testing;

