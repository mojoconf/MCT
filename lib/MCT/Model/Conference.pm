package MCT::Model::Conference;

use Mojo::Base 'MCT::Model';

my @valid = qw/name tagline/;
my %valid; @valid{@valid} = (1)x@valid;

sub get {
  my ($self, $ident, $cb) = @_;
  $self->_query(<<'  SQL', $ident, $cb);
    SELECT identifier, name, tagline
    FROM conferences
    WHERE identifier=?
  SQL
}

sub create {
  my ($self, $conf, $cb) = @_;
  my @values = @{$conf}{qw/identifier name tagline/};
  $self->_query(<<'  SQL', @values, $cb);
    INSERT INTO conferences (identifier, name, tagline)
    VALUES (?, ?, ?)
  SQL
}

sub update {
  my ($self, $ident, $conf, $cb) = @_;
  my @cols = grep { exists $valid{$_} } keys %$conf;
  my $cols = join ', ', map { "$_=?" } @cols;
  my @values = @{$conf}{@cols};
  $self->_query(<<"  SQL", @values, $ident, $cb);
    UPDATE conferences
    SET $cols
    WHERE identifier=?
  SQL
}

1;

