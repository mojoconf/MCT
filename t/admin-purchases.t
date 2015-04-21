use t::Helper;

my $t = t::Helper->t;
my %product = (stripeToken => 'tok_xyz');

my $conference = $t->app->model->conference(name => 'Fun fun fun')->save;
my $horse_ride = $conference->product(name => 'Horse ride', price => 4300)->save(sub {});
my $fun = $conference->product(name => 'Happy meal', price => 1200)->save(sub {});

$t->get_ok('/user/connect', form => {code => 42})->status_is(302);

$product{$_->[0]} = $horse_ride->${\$_->[1]} for ['amount', 'price'], ['currency', 'currency'], ['product_id', 'id'];
$t->post_ok('/fun-fun-fun/user/purchase', form => \%product)->status_is(302);

$product{$_->[0]} = $fun->${\$_->[1]} for ['amount', 'price'], ['currency', 'currency'], ['product_id', 'id'];
$t->post_ok('/fun-fun-fun/user/purchase', form => \%product)->status_is(302);

$t->get_ok('/fun-fun-fun/user/admin/purchases')->status_is(302);

$conference->grant_role('john_gh', 'admin');
$t->get_ok('/fun-fun-fun/user/admin/purchases')
  ->status_is(200)
  ->$_test_table([
    [
      ['a[href="/fun-fun-fun/user/john_gh/profile"]', 'john_gh'],
      ['a[href="/fun-fun-fun/events/2"]', 'Happy meal'],
      '12.00 USD',
      ['a[href="https://dashboard.stripe.com/payments/ch_15ceESLV2Qt9u2twk0Arv0Z8"]', 'Captured'],
    ],
    [
      ['a[href="/fun-fun-fun/user/john_gh/profile"]', 'john_gh'],
      ['a[href="/fun-fun-fun/events/1"]', 'Horse ride'],
      '43.00 USD',
      ['a[href="https://dashboard.stripe.com/payments/ch_15ceESLV2Qt9u2twk0Arv0Z8"]', 'Captured'],
    ],
    [
      'Total',
      '55.00 USD',
      '',
    ]
  ]);

done_testing;
