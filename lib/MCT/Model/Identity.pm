package MCT::Model::Identity;

use Mojo::Base 'MCT::Model';

has provider => sub { die '"provider" is required' };
has token => '';
has uid => '';
has username => '';

sub user {
  my ($self, $data, $cb) = @_;
  my $user = $self->new_object('User', db => $self->db);
  my $tx = $self->begin;

  # This is not the best solution, but it was the best I could come up with (batman)
  $tx->track($self, $user);

  # TODO: Add transactions?
  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      return $self->load($delay->begin) unless $self->in_storage;
      return $delay->pass('');
    },
    sub {
      my ($delay, $err) = @_;
      return $self->$cb($err, $user) if $err;
      return $user->username($self->username)->load($delay->begin) if $self->in_storage; # existing identity = existing user
      return $user->save($self->_provider_data($data), $delay->begin); # need to save user before identity
    },
    sub {
      my ($delay, $err) = @_;
      return $self->$cb($err, $user) if $err;
      return $self->$cb('', $user) if $self->in_storage; # existing user loaded
      return $self->username($user->username)->save($delay->begin); # user saved: save new identity
    },
    sub {
      my ($delay, $err) = @_;
      $tx->commit;
      $self->$cb($err, $user); # new identity saved
    },
  )->catch(sub{ $self->$cb($_[1], $user) })->wait;

  return $self;
}

sub _insert_sst {
  my $self = shift;

  <<'  SQL', map { $self->$_ } qw( username provider token uid );
    INSERT INTO user_identities (id_user, identity_provider, identity_token, identity_uid)
    VALUES(
      (SELECT u.id FROM users u WHERE u.username=?),
      ?, ?, ?
    )
    RETURNING id
  SQL
}

sub _load_sst {
  my $self = shift;
  my $key = $self->username ? 'u.username' : 'me.identity_uid';
  my @args = $self->username ? ($self->username, $self->provider) : ($self->uid, $self->provider);

  <<"  SQL", @args;
    SELECT
      me.id as id,
      me.identity_provider as provider,
      me.identity_token as token,
      me.identity_uid as uid,
      u.username as username
    FROM user_identities me
    JOIN users u ON u.id=me.id_user
    WHERE
      $key=?
      AND me.identity_provider=?
  SQL
}

sub _provider_data {
  my ($self, $data) = @_;

  return {
    email => $data->{email},
    name => $data->{name},
  };
}

sub _update_sst {
  my $self = shift;

  <<'  SQL', map { $self->$_ } qw( token id );
    UPDATE user_identities
    SET identity_token=?
    WHERE id=?
  SQL
}

sub TO_JSON {
  my $self = shift;
  return { map { ($_, $self->$_) } qw( provider uid username ) };
}

1;
