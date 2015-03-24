package MCT::Model::ConferenceProduct;

use MCT::Model -row;
use Mojo::DOM;
use Text::Markdown ();

col id => undef;

# required
col name => '';
col n_of => 1;
col price => 0;

# optional
col currency => 'USD';
col description => '';

has purchased => 0;
has conference => '';

sub description_to_html {
  my ($self, $args) = @_;
  my $dom = Mojo::DOM->new(Text::Markdown::markdown($self->description));

  if ((eval { $dom->children->first->tag } || '') ne 'h1') {
    $dom->prepend(sprintf '<h1>%s</h1>', $self->name);
  }

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

sub human_price { sprintf '%.2f', shift->price / 100 }

sub validate {
  my ($self, $validation) = @_;

  $validation->optional('currency')->like(qr/^\w{3}$/);
  $validation->optional('description')->like(qr/\w../);
  $validation->required('name')->like(qr/\w../);
  $validation->required('n_of')->like(qr/^[1-9]\d*$/);
  $validation->required('price')->like(qr/^\d+?$/);
  $validation;
}

sub _load_sst {
  sprintf('SELECT %s FROM conference_products WHERE id=?', join ', ', $_[0]->columns),
  $_[0]->id,
}

sub _insert_sst {
  my $self = shift;

  my $sql = sprintf <<'  SQL', join ', ', grep { $_ ne 'id' } $self->columns;
    INSERT INTO conference_products
    (conference_id, %s)
    VALUES (
      (SELECT c.id FROM conferences c WHERE c.identifier=?),
      ?, ?, ?, ?, ?
    )
    RETURNING id
  SQL

  return $sql, $self->conference, map { $self->$_ } grep { $_ ne 'id' } $self->columns;
}

sub _update_sst {
  my $self = shift;
  my @cols = grep { $_ ne 'id' } $self->columns;

  return(
    sprintf('UPDATE conference_products SET %s WHERE id=?', join ', ', map { "$_=?" } @cols),
    (map { $self->$_ } @cols),
    $self->id,
  );
}

sub TO_JSON {
  my $self = shift;
  return { map { ($_, $self->$_) } qw( name description price currency id ) };
}

1;
