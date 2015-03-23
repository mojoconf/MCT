package MCT::Model::UserProduct;

use MCT::Model -row;

col id => undef;

col currency => undef;
col external_link => undef;
col price => undef;
col product_id => undef;
col status => '';

has description => '';
has name => '';
has username => '';
has conference_name => '';

sub human_price { sprintf '%.2f', shift->price / 100 }

sub validate {
  my ($self, $validation) = @_;

  $validation->required('currency')->like(qr/^\w{3}$/);
  $validation->required('price')->like(qr/^\d+$/);
  $validation->required('product_id');
  $validation->required('username');
  $validation;
}

sub _load_sst {
  sprintf('SELECT %s FROM user_products WHERE id=?', join ', ', $_[0]->columns),
  $_[0]->id,
}

sub _insert_sst {
  my $self = shift;

  my $sql = sprintf <<'  SQL', join ', ', grep { $_ ne 'id' } $self->columns;
    INSERT INTO user_products
    (paid, user_id, %s)
    VALUES (
      CURRENT_TIMESTAMP,
      (SELECT u.id FROM users u WHERE u.username=?),
      ?, ?, ?, ?, ?
    )
    RETURNING id
  SQL

  return $sql, $self->username, map { $self->$_ } grep { $_ ne 'id' } $self->columns;
}

sub _update_sst {
  my $self = shift;
  my @cols = grep { $_ ne 'id' } $self->columns;

  return(
    sprintf(
      'UPDATE user_products SET %s WHERE id=?',
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
