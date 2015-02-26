package MCT::Model::User;

use Mojo::Base 'MCT::Model';

has email => '';
has name => '';
has username => sub { shift->email };

sub _load_sst {
  my $self = shift;
  my $key = $self->id ? 'id' : 'username';

  <<"  SQL", $self->$key;
    SELECT id, name, username, email
    FROM users
    WHERE $key=?
  SQL
}

sub _insert_sst {
  my $self = shift;
  <<'  SQL', map { $self->$_ } qw( name username email );
    INSERT INTO users (registered, name, username, email)
    VALUES (CURRENT_TIMESTAMP, ?, ?, ?)
    RETURNING id
  SQL
}

sub _update_sst {
  my $self = shift;
  <<"  SQL", map { $self->$_ } qw( name username email id );
    UPDATE users
    SET name=?, username=?, email=?
    WHERE id=?
  SQL
}

sub TO_JSON {
  my $self = shift;
  return { map { ($_, $self->$_) } qw( name username email id ) };
}

1;

