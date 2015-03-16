package MCT::Model::Conference;

use MCT::Model -row;
use MCT::Model::Countries;
use MCT::Model::Presentation;
use MCT::Model::User;

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

sub administrators {
  my ($self, $cb) = @_;

  my $sql = sprintf <<'  SQL', join ', ', map { "u.$_ as $_" } MCT::Model::User->columns;
    SELECT
      %s,
      c.identifier as conference,
      TRUE as is_admin,
      uc.going as is_going,
      uc.payed as payed
    FROM user_roles r
    JOIN conferences c ON c.id=r.conference_id
    JOIN users u ON u.id=r.user_id
    LEFT JOIN user_conferences uc ON uc.conference_id=r.conference_id
    WHERE r.role='conference admin'
      AND r.conference_id=?
    ORDER BY u.name
  SQL

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, $self->id, shift->begin) },
    sub {
      my ($delay, $err, $results) = @_;
      die $err if $err;
      $self->$cb(undef, [map { MCT::Model::User->new(%$_, db => $self->db) } $results->hashes->each]);
    },
  )->catch(sub{ $self->$cb($_[1], undef) })->wait;

  return $self;
}

sub grant_admin_role {
  my ($self, $user, $cb) = @_;
  $user = $user->username if eval { $user->isa('MCT::Model::User') };

  #TODO fail gracefully on duplicate insert. Catch exception?
  my $sql = <<'  SQL';
    INSERT INTO user_roles (user_id, conference_id, role)
    VALUES((SELECT id FROM users WHERE username=?), ?, 'conference admin');
  SQL

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, $user, $self->id, shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $self->$cb(undef);
    },
  )->catch(sub{ $self->$cb($_[1]) })->wait;

  return $self;
}

sub revoke_admin_role {
  my ($self, $user, $cb) = @_;
  $user = $user->username if eval { $user->isa('MCT::Model::User') };

  my $sql = <<'  SQL';
    DELETE FROM user_roles
    WHERE user_id=(SELECT id FROM users WHERE username=?) AND conference_id=? AND role='conference admin';
  SQL

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, $user, $self->id, shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $self->$cb(undef);
    },
  )->catch(sub{ $self->$cb($_[1]) })->wait;

  return $self;
}

sub attendees {
  my ($self, $cb) = @_;

  my $sql = sprintf <<'  SQL', join ', ', map { "u.$_ as $_" } MCT::Model::User->columns;
    SELECT
      %s,
      c.identifier as conference,
      (r.role IS NOT NULL) as is_admin,
      uc.going as is_going,
      uc.payed as payed
    FROM conferences c
    JOIN user_conferences uc ON uc.conference_id=c.id
    JOIN users u ON u.id=uc.user_id
    LEFT JOIN user_roles r ON r.user_id=u.id AND r.conference_id=c.id AND role='conference admin'
    WHERE c.identifier=?
    ORDER BY u.name
  SQL

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, $self->identifier, shift->begin) },
    sub {
      my ($delay, $err, $results) = @_;
      die $err if $err;
      $self->$cb(undef, [map { MCT::Model::User->new(%$_, db => $self->db) } $results->hashes->each]);
    },
  )->catch(sub{ $self->$cb($_[1], undef) })->wait;

  return $self;
}

sub country_name { MCT::Model::Countries->name_from_code($_[0]->country) || $_[0]->country }

sub presentations {
  my ($self, $cb) = @_;

  my $sql = sprintf <<'  SQL', join ', ', map { "p.$_ as $_" } MCT::Model::Presentation->columns;
    SELECT
      %s,
      c.identifier as conference,
      c.name as conference_name,
      u.username as author,
      u.name as author_name
    FROM conferences c
    LEFT JOIN presentations p ON p.conference_id=c.id
    LEFT JOIN users u ON u.id=p.user_id
    WHERE c.identifier=?
    ORDER BY c.created DESC, p.title
  SQL

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, $self->identifier, shift->begin) },
    sub {
      my ($delay, $err, $results) = @_;
      die $err if $err;
      $self->$cb(undef, [map { MCT::Model::Presentation->new(%$_, db => $self->db) } $results->hashes->each])
    },
  )->catch(sub{ $self->$cb($_[1], undef) })->wait;

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

