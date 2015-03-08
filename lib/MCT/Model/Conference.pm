package MCT::Model::Conference;

use MCT::Model -row;

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

sub country_name { $_[0]->{country_name} || $_[0]->country }

sub validate {
  my ($self, $validation) = @_;

  $validation->optional('address');
  $validation->optional('analytics_code')->like(qr{^[A-Z0-9-]+$});
  $validation->optional('city');
  $validation->optional('country');
  $validation->optional('identifier')->like(qr{^[a-z0-9-]+$});
  $validation->optional('location');
  $validation->optional('tagline')->size(3, 140); # 140 = tweet length
  $validation->optional('tags');
  $validation->optional('zip');
  $validation->required('domain');
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
    sprintf(<<'    SQL', join(', ', map { "me.$_ as $_" } $self->columns)),
    SELECT %s, c.name as country_name
    FROM conferences me
    JOIN countries c ON ( c.id = me.country )
    WHERE identifier=?
    SQL
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

