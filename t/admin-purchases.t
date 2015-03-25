use t::Helper;

my $t = t::Helper->t;

my $conference = $t->app->model->conference(name => 'Fun fun fun')->save;
my $horse_ride = $conference->product(name => 'Horse ride', price => 4300)->save(sub {});

$t->get_ok('/user/connect', form => {code => 42})->status_is(302);

my %product = (
  amount => $horse_ride->price,
  currency => $horse_ride->currency,
  product_id => $horse_ride->id,
  stripeToken => 'tok_xyz',
);
$t->post_ok('/fun-fun-fun/user/purchase', form => \%product)->status_is(302);

$t->get_ok('/fun-fun-fun/user/admin/purchases')->status_is(302);

$conference->grant_role('john_gh', 'admin');
$t->get_ok('/fun-fun-fun/user/admin/purchases')
  ->status_is(200)
  ->$_test_table([
    [
      'john_gh',
      ['a[href="/fun-fun-fun/events/1"]', 'Horse ride'],
      '43.00 USD',
      ['a[href="https://dashboard.stripe.com/test/payments/ch_15ceESLV2Qt9u2twk0Arv0Z8"]', 'Captured'],
    ]
  ]);

done_testing;
