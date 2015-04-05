package MCT::Model::User;

use MCT::Model -row;
use MCT::Model::UserProduct;
use Mojo::Util 'xml_escape';
use Text::Markdown ();

col id => undef;

# optional
col address => '';
col bio => '';
col avatar_url => '';
col city => '';
col country => '';
col t_shirt_size => '';
col web_page => '';
col zip => '';

# required
col email => '';
col name => '';
col username => sub { shift->email };

sub avatar {
  my ($self, %args) = @_;
  my $url = Mojo::URL->new($self->avatar_url);

  $url->query({size => $args{size}}) if $args{size};
  $url;
}

sub bio_to_html {
  my ($self, $args) = @_;
  my $dom = Mojo::DOM->new(Text::Markdown::markdown(xml_escape $self->bio));

  if (my $level = $args->{headings}) {
    for my $e ($dom->find('h1,h2,h3,h4,h5,h6')->each) {
      my $n = $e->tag =~ /(\d+)/ ? $1 : 6;
      $n += $level;
      $n = 6 if $n > 6;
      $e->tag("h$n");
    }
  }

  return $dom;
}

sub purchase {
  my ($self, $product) = @_;

  $self->new_object('UserProduct' => (
    currency => $product->currency,
    description => $product->description,
    price => $product->price,
    name => $product->name,
    product_id => $product->id,
    username => $self->username,
  ));
}

sub purchases {
  my ($self, $cb) = @_;

  my $sql = sprintf <<'  SQL';
  SELECT
    cp.id as id,
    cp.name as name,
    cp.description as description,
    cp.currency as currency,
    up.price as price,
    c.name as conference_name
  FROM users u
  JOIN user_products up ON up.user_id=u.id
  JOIN conference_products cp ON cp.id=up.product_id
  JOIN conferences c ON c.id=cp.conference_id
  WHERE u.username=? AND up.status=?
  ORDER BY up.paid DESC, cp.name
  SQL

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, $self->username, MCT::Model::UserProduct::CAPTURED_STATUS, shift->begin) },
    sub {
      my ($delay, $err, $results) = @_;
      die $err if $err;
      $self->$cb('', [map { $self->new_object(UserProduct => %$_, username => $self->username) } $results->hashes->each]);
    },
  )->catch(sub{ $self->$cb($_[1], []) })->wait;

  return $self;
}

sub validate {
  my ($self, $validation) = @_;

  $validation->optional('address');
  $validation->optional('avatar_url');
  $validation->optional('city');
  $validation->optional('bio');
  $validation->optional('country')->country;
  $validation->optional('t_shirt_size')->in($self->valid_t_shirt_sizes);
  $validation->optional('web_page')->like(qr!^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?!); # from Mojo::URL
  $validation->optional('zip')->like(qr!^[a-z0-9-]+$!i);

  $validation->required('email')->like(qr{\@}); # poor mans email regex
  $validation->required('name')->like(qr{\w..});
  $validation->required('username')->like(qr{^...});
  $validation;
}

sub valid_t_shirt_sizes { qw( XS S M XL XXL ) }

sub presentations {
  my ($self, $cb) = @_;
  #TODO add ability to only select by conference
  #TODO select status once it exists

  my $sql = <<'  SQL';
    SELECT
      e.id,
      c.identifier as conference,
      c.name as conference_name,
      u.username as author,
      u.name as author_name,
      e.duration,
      e.status,
      e.identifier as identifier,
      e.title as title,
      e.description as description
    FROM events e
    JOIN conferences c ON c.id=e.conference_id
    JOIN users u ON u.id=e.user_id
    WHERE e.user_id=?
    ORDER BY c.created DESC, e.title
  SQL

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, $self->id, shift->begin) },
    sub {
      my ($delay, $err, $results) = @_;
      die $err if $err;
      $self->$cb(undef, [map { $self->new_object(Presentation => %$_) } $results->hashes->each]);
    },
  )->catch(sub{ $self->$cb($_[1], undef) })->wait;

  return $self;
}

sub _load_sst {
  my $self = shift;
  my $key = $self->id ? 'id' : 'username';

  return(
    sprintf('SELECT %s FROM users WHERE %s=?', join(', ', $self->columns), $key),
    $self->$key,
  );
}

sub _insert_sst {
  my $self = shift;
  my @cols = grep { $_ ne 'id' } $self->columns;

  return(
    sprintf(
      'INSERT INTO users (registered, %s) VALUES (CURRENT_TIMESTAMP, %s) RETURNING id',
      join(', ', @cols),
      join(', ', map { '?' } @cols),
    ),
    map { $self->$_ } @cols
  );
}

sub _update_sst {
  my $self = shift;
  my @cols = grep { $_ ne 'id' } $self->columns;

  return(
    sprintf(
      'UPDATE users SET %s WHERE id=?',
      join(', ', map { "$_=?" } @cols),
    ),
    (map { $self->$_ } @cols),
    $self->id,
  );
}

sub TO_JSON {
  my $self = shift;
  return { map { ($_, $self->$_) } qw( name username email id ) };
}

1;

