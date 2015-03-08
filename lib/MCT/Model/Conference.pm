package MCT::Model::Conference;

use MCT::Model -row;

has analytics_code => '';
has identifier => sub {
  my $self = shift;
  my $identifier = lc $self->name;
  $identifier =~ s!\W!-!g;
  $identifier;
};
has name => '';
has tagline => '';

sub validate {
  my ($self, $validation) = @_;

  $validation->optional('analytics_code')->like(qr{^[A-Z0-9-]+$});
  $validation->optional('identifier')->like(qr{^[a-z0-9-]+$});
  $validation->required('name')->size(4, 20);
  $validation->optional('tagline')->size(3, 140); # 140 = tweet length

  unless ($validation->output->{identifier}) {
    $validation->output->{identifier} = substr lc($validation->param('name') || ''), 0, 20;
    $validation->output->{identifier} =~ s![^a-z0-9-]+!-!;
  }

  return $validation;
}

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

