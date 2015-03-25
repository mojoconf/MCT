use t::Helper;

my $t = t::Helper->t;
my $app = $t->app;
my ($err, $meta);

my $conference = $app->model->conference(name => 'Role changers assosiated limited', country => 'US')->save;
my $user = $app->model->user(username => 'roger', email => 'roger@example.com')->save;

for my $m (qw( has_role revoke_role grant_role )) {
  local $@;
  eval { $conference->$m('roger', 'invalid_role') };
  like $@, qr{invalid_role}, "$m: invalid role";
}

ok !$conference->has_role('roger', 'admin'), 'roger does not have admin';

$conference->revoke_role('roger', 'admin');
ok !$conference->has_role({id => $user->id}, 'admin'), 'roger still does not have admin';

$conference->grant_role('roger', 'admin');
is_deeply($conference->has_role($user, 'admin'), {}, 'roger has admin');

$conference->grant_role({id => $user->id}, 'admin', sub { (my $conference, $err) = @_; });
ok !$err, 'grant_role cb: no err';
is_deeply($conference->has_role({username => $user->username}, 'admin'), {}, 'can grant again');

$conference->has_role('roger', 'admin', sub { (my $conference, $err, $meta) = @_ });
ok !$err, 'has_role cb: no err';
is_deeply $meta, {}, 'has_role cb: meta';

$conference->revoke_role({id => $user->id}, 'admin', sub { (my $conference, $err) = @_ });
ok !$err, 'revoke_role cb: no err';
ok !$conference->has_role('roger', 'admin'), 'roger got admin revoked';

done_testing;
