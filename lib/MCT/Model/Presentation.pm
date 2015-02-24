package MCT::Model::Presentation;

use Mojo::Base 'MCT::Model';

my @valid = qw/conference author url_name title subtitle abstract/;
my %valid; @valid{@valid} = (1)x@valid;

sub get {
  my ($self, $conference, $url_name, $cb) = @_;
  $self->_query(<<'  SQL', $conference, $url_name, $cb);
    SELECT
      c.name AS conference,
      u.name AS author,
      url_name,
      title,
      subtitle,
      abstract
    FROM presentations
    JOIN conferences c ON c.id=conference
    JOIN users u ON u.id=author
    WHERE
      c.identifier=?
      AND url_name=?
  SQL
}

sub create {
  my ($self, $presentation, $cb) = @_;
  my @values = @{$presentation}{qw/conference author url_name title subtitle abstract/};
  # http://sqlfiddle.com/#!15/e1168/1/3
  $self->_query(<<'  SQL', @values, $cb);
    INSERT INTO presentations (conference, author, url_name, title, subtitle, abstract)
    VALUES(
      (SELECT c.id FROM conferences c WHERE c.identifier=?),
      (SELECT u.id FROM users u WHERE u.username=?),
      ?, ?, ?, ?
    )
  SQL
}

sub update {
  my ($self, $conference, $url_name, $presentation, $cb) = @_;
  my @cols = grep { exists $valid{$_} } keys %$presentation;
  my $cols = join ', ', map { "$_=?" } @cols;
  my @values = @{$presentation}{@cols};
  $self->_query(<<"  SQL", @values, $conference, $url_name, $cb);
    UPDATE presentations
    SET $cols
    JOIN conferences c ON c.identifier=?
    WHERE url_name=?
  SQL
}

1;
