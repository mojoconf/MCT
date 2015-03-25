package MCT::Model::Conference;

use MCT::Model -row;
use MCT::Model::Countries;
use MCT::Model::ConferenceProduct;
use MCT::Model::UserProduct;
use MCT::Model::User;
use Mojo::JSON 'decode_json';

my %ROLES = (
  admin => 'conference admin',
);

col id => undef;
col address => '';
col analytics_code => '';
col city => '';
col country => '';
col domain => '';
col identifier => sub {
  my $self = shift;
  my $identifier = lc $self->name;
  $identifier =~ s!\W!-!g;
  $identifier;
};
col name => '';
col location => '';
col tagline => '';
col tags => '';
col zip => '';

sub country_name { MCT::Model::Countries->name_from_code($_[0]->country) || $_[0]->country }

# $self->grant_role($username, "admin");
# $self->grant_role({username => $username}, "admin");
# $self->grant_role({id => $uid}, "admin");
sub grant_role {
  my ($self, $args, $role, $cb) = @_;
  my (@res, $sql, @bind);

  $role = $ROLES{$role} || die "Invalid role: $role";
  $args = {username => $args} unless ref $args;
  $cb ||= sub { @res = @_[1,2] };

  if ($args->{id}) {
    $sql = 'INSERT INTO user_roles (user_id, conference_id, role) VALUES(?, ?, ?)';
    @bind = ($args->{id}, $self->id, $role);
  }
  else {
    $sql = 'INSERT INTO user_roles (user_id, conference_id, role) VALUES((SELECT id FROM users WHERE username=?), ?, ?)';
    @bind = ($args->{username}, $self->id, $role);
  }

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, @bind, shift->begin) },
    sub {
      my ($delay, $err, $res) = @_;
      return $self->$cb('') if !$err or $res->sth->state == 23505; # unique_violation, http://www.postgresql.org/docs/9.3/static/errcodes-appendix.html
      return $self->$cb($err || '');
    },
  )->catch(sub{ $self->$cb($_[1]) })->wait;

  die $res[1] if $res[1];
  return $res[2] if @res;
  return $self;
}

sub has_role {
  my ($self, $args, $role, $cb) = @_;
  my (@res, $sql, @bind);

  $role = $ROLES{$role} || die "Invalid role: $role";
  $args = {username => $args} unless ref $args;
  $cb ||= sub { @res = @_[1,2] };

  if ($args->{id}) {
    $sql = 'SELECT meta FROM user_roles WHERE user_id=? AND conference_id=? AND role=?';
    @bind = ($args->{id}, $self->id, $role);
  }
  else {
    $sql = 'SELECT meta FROM user_roles WHERE user_id=(SELECT id FROM users WHERE username=?) AND conference_id=? AND role=?';
    @bind = ($args->{username}, $self->id, $role);
  }

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, @bind, shift->begin) },
    sub { $self->$cb($_[1], eval { decode_json($_[2]->array->[0]) }); },
  )->catch(sub{ $self->$cb($_[1], undef) })->wait;

  die $res[0] if $res[0];
  return $res[1] if @res;
  return $self;
}

sub presentations {
  my ($self, $cb) = @_;

  my $sql = <<'  SQL';
    SELECT
      p.id,
      p.duration,
      p.status,
      p.url_name as url_name,
      p.title as title,
      p.abstract as abstract,
      u.username as author,
      u.name as author_name
    FROM presentations p
    JOIN conferences c ON c.id=p.conference_id
    JOIN users u ON u.id=p.user_id
    WHERE c.identifier=?
    ORDER BY p.title
  SQL

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, $self->identifier, shift->begin) },
    sub {
      my ($delay, $err, $results) = @_;
      die $err if $err;
      $self->$cb(undef, [
        map {
          my $data = $_;
          $data->{conference} = $self->identifier;
          $data->{conference_name} = $self->name;
          $self->new_object(Presentation => %$data);
        } $results->hashes->each
      ]);
    },
  )->catch(sub{ $self->$cb($_[1], undef) })->wait;

  return $self;
}

sub product {
  my $self = shift;
  $self->new_object('ConferenceProduct', conference => $self->identifier, @_);
}

sub products {
  my ($self, $args, $cb) = @_;
  my ($sql, @bind);

  if ($args->{uid}) {
    @bind = ($args->{uid}, MCT::Model::UserProduct::CAPTURED_STATUS, $self->identifier);
    $sql = sprintf <<'    SQL', join ', ', map { "p.$_ AS $_" } MCT::Model::ConferenceProduct->columns;
    SELECT
      %s,
      up.price as purchased
    FROM conferences c
    JOIN conference_products p ON p.conference_id=c.id
    LEFT JOIN user_products up ON (up.product_id=p.id AND up.user_id=? AND up.status=?)
    WHERE c.identifier=?
    ORDER BY name, price
    SQL
  }
  else {
    @bind = ($self->identifier);
    $sql = sprintf <<'    SQL', join ', ', map { "p.$_ AS $_" } MCT::Model::ConferenceProduct->columns;
    SELECT %s
    FROM conferences c
    JOIN conference_products p ON p.conference_id=c.id
    WHERE c.identifier=?
    ORDER BY name, price
    SQL
  }

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, @bind, shift->begin) },
    sub {
      my ($delay, $err, $results) = @_;
      my %defaults = (conference => $self->identifier, db => $self->db);
      die $err if $err;
      $self->$cb('', [map { MCT::Model::ConferenceProduct->new(%$_, %defaults) } $results->hashes->each]);
    },
  )->catch(sub{ $self->$cb($_[1], []) })->wait;

  return $self;
}

sub purchases {
  my ($self, $cb) = @_;

  my $sql = sprintf <<'  SQL';
  SELECT
    cp.id as product_id,
    cp.name as name,
    cp.description as description,
    up.currency as currency,
    up.external_link as external_link,
    up.price as price,
    up.status as status,
    u.username as username,
    c.name as conference_name
  FROM users u
  JOIN user_products up ON up.user_id=u.id
  JOIN conference_products cp ON cp.id=up.product_id
  JOIN conferences c ON c.id=cp.conference_id
  WHERE c.id=?
  ORDER BY up.paid DESC, cp.name
  SQL

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, $self->id, shift->begin) },
    sub {
      my ($delay, $err, $results) = @_;
      die $err if $err;
      $self->$cb('', [map { $self->new_object(UserProduct => %$_) } $results->hashes->each]);
    },
  )->catch(sub{ $self->$cb($_[1], []) })->wait;

  return $self;
}

# $self->revoke_role($username, "admin");
# $self->revoke_role({username => $username}, "admin");
# $self->revoke_role({id => $uid}, "admin");
sub revoke_role {
  my ($self, $args, $role, $cb) = @_;
  my (@res, $sql, @bind);

  $role = $ROLES{$role} || die "Invalid role: $role";
  $args = {username => $args} unless ref $args;
  $cb ||= sub { @res = @_[1,2] };

  if ($args->{id}) {
    $sql = 'DELETE FROM user_roles WHERE user_id=? AND conference_id=? AND role=?';
    @bind = ($args->{id}, $self->id, $role);
  }
  else {
    $sql = 'DELETE FROM user_roles WHERE user_id=(SELECT id FROM users WHERE username=?) AND conference_id=? AND role=?';
    @bind = ($args->{username}, $self->id, $role);
  }

  Mojo::IOLoop->delay(
    sub { # make sure we always have someone with a given role
      my $sql = 'SELECT user_id FROM user_roles WHERE conference_id=? AND role=? LIMIT 2';
      $self->_query($sql, $self->id, $role, shift->begin);
    },
    sub {
      my ($delay, $err, $results) = @_;
      $self->$cb("At least one user need to have the role $role.") if +($results->rows || 0) <= 1;
      $self->_query($sql, @bind, $delay->begin);
    },
    sub { $self->$cb($_[1]); },
  )->catch(sub{ $self->$cb($_[1]) })->wait;

  die $res[1] if $res[1];
  return $res[2] if @res;
  return $self;
}

sub users {
  my ($self, $cb) = @_;

  my $sql = sprintf <<'  SQL', join ', ', map { "u.$_ as $_" } MCT::Model::User->columns;
    SELECT %s
    FROM user_roles ur
    JOIN users u ON u.id=ur.user_id
    WHERE ur.conference_id=?
    ORDER BY u.name
  SQL

  Mojo::IOLoop->delay(
    sub {
      $self->_query($sql, $self->id, shift->begin);
    },
    sub {
      my ($delay, $err, $results) = @_;
      die $err if $err;
      $self->$cb('', [map { $self->new_object(User => %$_) } $results->hashes->each]);
    },
  )->catch(sub{ $self->$cb($_[1]) })->wait;

  return $self;
}

sub validate {
  my ($self, $validation) = @_;

  $validation->optional('address');
  $validation->optional('analytics_code')->like(qr{^[A-Z0-9-]+$});
  $validation->optional('city');
  $validation->optional('country')->country;
  $validation->optional('identifier')->like(qr{^[a-z0-9-]+$});
  $validation->optional('location');
  $validation->optional('tagline')->size(3, 140); # 140 = tweet length
  $validation->optional('tags');
  $validation->optional('zip');
  $validation->optional('domain');
  $validation->required('name')->size(4, 20);

  unless ($validation->output->{identifier}) {
    $validation->output->{identifier} = substr lc($validation->param('name') || ''), 0, 20;
    $validation->output->{identifier} =~ s![^a-z0-9-]+!-!;
  }

  return $validation;
}

sub _load_sst {
  my $self = shift;

  return(
    sprintf('SELECT %s FROM conferences WHERE identifier=?', join ', ', $self->columns),
    $self->identifier,
  );
}

sub _insert_sst {
  my $self = shift;
  my @cols = grep { $_ ne 'id' } $self->columns;

  return(
    sprintf(
      'INSERT INTO conferences (created, %s) VALUES (CURRENT_TIMESTAMP, %s) RETURNING id',
      join(',', @cols),
      join(',', map { '?' } @cols),
    ),
    map { $self->$_ } @cols
  );
}

sub _update_sst {
  my $self = shift;
  my @cols = grep { $_ ne 'id' } $self->columns;

  return(
    sprintf(
      'UPDATE conferences SET %s WHERE id=?',
      join(',', map { "$_=?" } @cols),
    ),
    (map { $self->$_ } @cols),
    $self->id,
  );
}

sub TO_JSON {
  my $self = shift;
  return { map { ($_, $self->$_) } qw( identifier name tagline id ) };
}

1;
