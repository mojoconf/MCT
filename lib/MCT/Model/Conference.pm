package MCT::Model::Conference;

use Mojo::Base 'MCT::Model';

has identifier => '';
has name => '';
has tagline => '';

sub _load_sst {
  my $self = shift;
  <<'  SQL', $self->identifier;
    SELECT id, identifier, name, tagline
    FROM conferences
    WHERE identifier=?
  SQL
}

sub _insert_sst {
  my $self = shift;
  <<'  SQL', map { $self->$_ } qw( identifier name tagline );
    INSERT INTO conferences (created, identifier, name, tagline)
    VALUES (CURRENT_TIMESTAMP, ?, ?, ?)
    RETURNING id
  SQL
}

sub _update_sst {
  my $self = shift;
  <<'  SQL', map { $self->$_ } qw( identifier name tagline id );
    UPDATE conferences
    SET identifier=?, name=?, tagline=?
    WHERE id=?
  SQL
}

sub TO_JSON {
  my $self = shift;
  return { map { ($_, $self->$_) } qw( identifier name tagline id ) };
}

1;

