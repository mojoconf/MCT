package MCT::Model::Conference;

use Mojo::Base 'MCT::Model';

has analytics_code => '';
has identifier => sub {
  my $self = shift;
  my $identifier = lc $self->name;
  $identifier =~ s!\W!-!g;
  $identifier;
};
has name => '';
has tagline => '';

sub _load_sst {
  my $self = shift;
  <<'  SQL', $self->identifier;
    SELECT id, identifier, name, analytics_code, tagline
    FROM conferences
    WHERE identifier=?
  SQL
}

sub _insert_sst {
  my $self = shift;
  <<'  SQL', map { $self->$_ } qw( identifier name analytics_code tagline );
    INSERT INTO conferences (created, identifier, name, analytics_code, tagline)
    VALUES (CURRENT_TIMESTAMP, ?, ?, ?, ?)
    RETURNING id
  SQL
}

sub _update_sst {
  my $self = shift;
  <<'  SQL', map { $self->$_ } qw( identifier name analytics_code tagline id );
    UPDATE conferences
    SET identifier=?, name=?, analytics_code=?, tagline=?
    WHERE id=?
  SQL
}

sub TO_JSON {
  my $self = shift;
  return { map { ($_, $self->$_) } qw( identifier name tagline id ) };
}

1;

