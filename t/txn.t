use t::Helper;

my $t = t::Helper->t;
my $app = $t->app;

my $user = $app->model->user;
my $txn1 = $user->begin;
my $txn2 = $user->begin;

ok $txn1->dbh, 'first transaction can roll back';
ok !$txn2->dbh, 'second transaction cannot roll back';

done_testing;
