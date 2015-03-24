use t::Helper;
my $t = t::Helper->t;

my $conference = $t->app->model->conference(name => 'My Little Pony', country => 'SE')->save(sub {});

$t->get_ok('/my-little-pony/register')->status_is(200)
  ->element_exists('table.products')
  ->text_is('table.products tbody td', '') # no data in table
  ->element_exists('a[href="/user/connect"]');

# require log in to purchase
$t->post_ok('/my-little-pony/user/purchase')->status_is(302)->header_like(Location => qr{/mocked/oauth/authorize});

my $horse_ride = $conference->product(name => 'Horse ride', price => 4300)->save(sub {});
my $haunted_house = $conference->product(name => 'Haunted house', price => 9990, currency => 'NOK')->save(sub {});

$t->get_ok('/my-little-pony/register')->status_is(200)
  ->element_exists('table.products')
  ->element_exists_not('form[method="POST"][action="/my-little-pony/user/purchase"]')
  ->text_is('a[href="/user/connect"]', 'Register')
  ->$_test_table('table.products tbody', [
    [
      'Haunted house',
      ['a[data-amount="9990"]', 'Buy ticket'],
      '99.90 NOK',
    ],
    [
      'Horse ride',
      ['a[data-amount="4300"]', 'Buy ticket'],
      '43.00 USD',
    ],
  ]);

# make sure we get redirected back to register page, after clicking on "Login"
$t->get_ok('/user/connect?code=42', {Referer => $t->tx->req->url->to_abs})->status_is(302)->header_like(Location => qr{/my-little-pony/register$});

$t->get_ok('/my-little-pony/register')->status_is(200)
  ->element_exists('table.products')
  ->element_exists_not('p[class="error"]')
  ->$_test_table('table.products tbody', [
    [
      'Haunted house',
      ['a.custom-stripe-button[data-amount="9990"][data-product-id]', 'Buy ticket'],
      '99.90 NOK',
    ],
    [
      'Horse ride',
      ['a.custom-stripe-button[data-amount="4300"][data-product-id]', 'Buy ticket'],
      '43.00 USD',
    ],
  ]);

$t->get_ok('/my-little-pony/user/tickets')->status_is(200)->text_is('h3', 'No tickets have been purchased.');

my %form;
for my $i (
  [],
  [amount => $haunted_house->price + $horse_ride->price + 1],
  [currency => 'USD'],
  [product_id => 42],
) {
  $form{$i->[0]} = $i->[1] if $i->[0];
  $t->post_ok('/my-little-pony/user/purchase', form => \%form)->status_is(400)->element_exists('p.error');
}

$form{stripeToken} = 'tok_xyz';
$t->post_ok('/my-little-pony/user/purchase', form => \%form)->status_is(400)->text_like('p.error', qr{Unknown product});

$form{product_id} = join ',', $haunted_house->id, $horse_ride->id;
$t->post_ok('/my-little-pony/user/purchase', form => \%form)->status_is(400)->text_like('p.error', qr{Invalid amount});

$form{amount} = $haunted_house->price + $horse_ride->price;
$t->post_ok('/my-little-pony/user/purchase', form => \%form)->status_is(400)->text_like('p.error', qr{Different currencies});

$haunted_house->currency('USD')->save(sub {});
$t->post_ok('/my-little-pony/user/purchase', form => \%form)->status_is(302)->header_is(Location => '/my-little-pony/user/tickets');

$t->get_ok($t->tx->res->headers->location)->status_is(200)
  ->element_exists('i.fa-shopping-cart')
  ->element_exists('p.info.big')
  ->element_exists('i.fa-list')
  ->$_test_table('table.tickets tbody', [
    [
      'My Little Pony',
      'Horse ride',
      '43.00 USD',
    ],
    [
      'My Little Pony',
      'Haunted house',
      '99.90 USD',
    ],
  ]);

done_testing;
