package MCT::Controller::Conference;

use Mojo::Base 'Mojolicious::Controller';
use List::Util 'sum';

sub create {
  my $c = shift;
  my $conference = $c->model->conference;
  my $validation = $c->validation;

  $c->stash(conference => $conference);

  if ($conference->validate($validation)->has_error) {
    return;
  }

  $c->delay(
    sub { $c->_find_latest_identifier(shift->begin) },
    sub {
      my ($delay, $err, $res) = @_;
      die $err if $err;
      return $c->reply->exception('TODO: Add support for creating more conferences') if $res->rows;
      return $conference->save($validation->output, shift->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->redirect_to(landing_page => cid => $conference->identifier);
    },
  );
}

sub load {
  my $c = shift;
  my $conference = $c->model->conference(identifier => $c->stash('cid'));

  # "state" will be passed back to us from the OAuth2 provider
  $c->stash->{connect_args}{state} = $c->stash('cid');

  $c->stash(conference => $conference);
  $c->delay(
    sub { $conference->load(shift->begin); },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->continue if $conference->in_storage;
      return $c->render('/conference/create');
    },
  );

  return;
}

sub landing_page {
  my $c = shift;

  $c->respond_to(
    json => {json => $c->stash('conference')},
    any => {},
  );
}

sub latest_conference {
  my $c = shift;

  $c->delay(
    sub { $c->_find_latest_identifier(shift->begin); },
    sub {
      my ($delay, $err, $res) = @_;
      die $err if $err;
      $res = $res->hash;
      return $c->redirect_to(landing_page => cid => $res->{identifier}) if $res;
      return $c->render('/conference/create', conference => $c->_default_conference);
    },
  );
}

sub page {
  my $c = shift;
  my $cid = $c->stash('cid');
  my $page = $c->stash('page');

  $c->render("$cid/$page");
}

sub purchase {
  my $c = shift;
  my $user = $c->model->user(id => $c->session('uid'));
  my $validation = $c->validation;

  $validation->required($_) for qw( amount currency product_id stripeToken );
  $validation->has_error and return $c->register('There was some missing values in the checkout form. Please try again.');

  $c->delay(
    sub { # 0. load user
      $user->load(shift->begin)
    },
    sub { # 1. load products from database, validate and create items
      $c->param(stripeEmail => $user->email);
      $c->_products_to_items($user, shift->begin);
    },
    sub { # 2. create charge
      my ($delay, $err, $items) = @_;
      my %args;
      return $c->register($err) if $err;
      $args{description} = join ' + ', map { $_->name } @$items;
      $args{metadata} = { map { ($_ => $user->$_) } qw( id name username ) };
      $c->stripe->create_charge(\%args, $delay->begin);
      $delay->pass($items);
    },
    sub { # 3. save items with charge id
      my ($delay, $err, $charge, $items) = @_;
      return $c->register($err) if $err;
      $_->external_link("stripe://$charge->{id}")->status($_->CREATED_STATUS) for @$items;
      $c->_save_items($items, $delay->begin);
      $delay->pass($charge, $items);
    },
    sub { # 4. capture charge
      my ($delay, $err, $charge, $items) = @_;
      die $err if $err;
      $c->stripe->capture_charge($charge, $delay->begin);
      $delay->pass($items);
    },
    sub { # 5. update items
      my ($delay, $err, $charge, $items) = @_;
      $_->status($err || $_->CAPTURED_STATUS) for @$items;
      $c->_save_items($items, $delay->begin);
      $delay->pass($charge, $items);
    },
    sub { # 6. render
      my ($delay, $err, $charge, $items) = @_;
      $c->app->log->error("Failed to save items @{[join ',', map {$_->id} @$items]}: $err") if $err;
      $c->flash(purchased_product_id => $c->param('product_id'));
      $c->redirect_to('user.purchases');
    },
  );
}

sub register {
  my ($c, $err) = @_;

  if ($err) {
    $c->app->log->debug("purchase: $err");
    $c->stash(error => $err);
    $c->stash(template => 'conference/register')->res->code(400);
  }

  $c->delay(
    sub { $c->stash('conference')->products({ uid => $c->session('uid') }, shift->begin); },
    sub {
      my ($delay, $err, $products) = @_;
      $c->render(products => $products);
    },
  );
}

sub _default_conference {
  shift->model->conference(
    analytics_code => 'UA-60226126-1',
    identifier => '2015',
    name => 'Mojoconf 2015',
    tagline => 'Be there or be square.',
  );
}

sub schedule {
  my $c = shift;

  $c->stash(show_schedule => 1);
  $c->respond_to(
    ical => \&_schedule_as_ical,
    json => \&_schedule_as_json,
    any => sub {shift->render},
  );
}

sub _find_latest_identifier {
  my ($c, $cb) = @_;
  $c->model->db->query('SELECT identifier FROM conferences ORDER BY created DESC LIMIT 1', $cb);
}

sub _products_to_items {
  my ($c, $user, $cb) = @_;
  my $amount = $c->param('amount');
  my $currency = $c->param('currency');
  my ($err, @products, @steps);

  for my $id (split /,/, $c->param('product_id')) {
    push @steps, sub { $_[1] and die $_[1]; push @products, $c->stash('conference')->product(id => $id)->load(shift->begin); };
  }

  $c->delay(
    @steps,
    sub {
      my ($delay, $err) = @_;
      my @items = map { $user->purchase($_) } @products;
      return $c->$cb("Unknown product.", []) unless @items = grep { $_->price } @items;
      return $c->$cb("Invalid amount. ($amount)", []) unless $amount eq sum(map { $_->price } @items);
      return $c->$cb("Different currencies are not supported.", []) unless @items == grep { $currency eq $_->currency } @items;
      return $c->$cb('', \@items);
    },
  );
}

sub _save_items {
  my ($c, $items, $cb) = @_;
  my @steps;

  for my $item (@$items) {
    push @steps, sub { $_[1] and die $_[1]; $item->save(shift->begin); };
  }

  $c->delay(@steps, sub { $c->$cb($_[1]) });
}

sub _schedule_as_ical {
  my $c = shift;

  $c->reply->ical({
    events => [
      { summary => 'Non-blocking services with Mojolicious', dtstart => '20150604T090000', dtend => '20150604T160000', description => 'https://www.mojoconf.com/2015/events/1' },
      { summary => 'Modernizing CGI.pm Apps with Mojolicious', dtstart => '20150604T090000', dtend => '20150604T160000', description => 'https://www.mojoconf.com/2015/events/2' },
      { summary => 'Hackathon', dtstart => '20150606T090000', dtend => '20150606T160000', description => 'https://www.mojoconf.com/2015' }
    ],
    properties => $c->_schedule_properties,
  });
}

sub _schedule_as_json {
  my $c = shift;

  $c->render(json => {
    events => [
      { id => 1, title => 'Non-blocking services with Mojolicious', start => '2015-06-04T09:00:00', end => '2015-06-04T16:00:00', className => 'training', url => 'https://www.mojoconf.com/2015/events/1' },
      { id => 2, title => 'Modernizing CGI.pm Apps with Mojolicious', start => '2015-06-04T09:00:00', end => '2015-06-04T16:00:00', className => 'training', url => 'https://www.mojoconf.com/2015/events/2' },
      { title => 'Talks', start => '2015-06-05', className => 'talks', rendering => 'background', url => 'https://www.mojoconf.com/2015' },
      { title => 'Hackathon', start => '2015-06-06', className => 'hackathon', rendering => 'background', url => 'https://www.mojoconf.com/2015' },
      { title => 'Hackathon', start => '2015-06-06T09:00:00', end => '2015-06-06T16:00:00', className => 'hackathon', url => 'https://www.mojoconf.com/2015' }
    ],
    defaults => {},
    properties => $c->_schedule_properties,
  });
}

sub _schedule_properties {
  my $c = shift;
  my $conference = $c->stash('conference');

  return {
    prodid => sprintf('-//%s//NONSGML %s//EN', $conference->domain || 'MCT', $conference->identifier),
    x_wr_caldesc => $conference->tagline,
    x_wr_calname => $conference->name,
  };
}

1;
