package MCT::Model::Presentation;

use MCT::Model -row;
use Text::Markdown ();
use Mojo::Util 'xml_escape';

my @VALID_STATUS = qw( TENTATIVE CONFIRMED CANCELLED NEEDS-ACTION COMPLETED IN-PROCESS );

col description => '';
col duration => 20;
col external_url => '';
col identifier => '';
col sequence => 0;
col start_time => undef,
col status => 'TENTATIVE';
col title => '';
col type => 'talk';

has author_name => '';
has author => '';
has conference => '';
has conference_name => '';

# used by an admin to change the status of the presentation
sub change_status {
  my ($self, $status, $cb) = @_;

  unless (grep { $_ eq $status } @VALID_STATUS) {
    return $self->tap($cb, 'Invalid state');
  }

  my $sql = <<'  SQL';
    UPDATE events e
    SET status=?
    FROM conferences c
    WHERE c.identifier=? AND e.identifier=?
  SQL

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, $status, $self->conference, $self->identifier, shift->begin) },
    sub {
      my ($delay, $err, $res) = @_;
      $self->status($status) unless $err;
      $self->$cb($err);
    },
  )->catch(sub{ $self->$cb($_[1]) })->wait;

  return $self;
}

sub description_to_html {
  my ($self, $args) = @_;
  my $dom = Mojo::DOM->new(Text::Markdown::markdown(xml_escape $self->description));

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

sub validate {
  my ($self, $validation) = @_;

  $validation->required('title');
  $validation->required('description');
  $validation->optional('identifier');
  $validation->optional('duration')->in($self->valid_durations);

  my $output = $validation->output;
  if (my $title = $output->{title} and not $output->{identifier}) {
    $title =~ s/\s+/-/g;
    $title =~ s/(\W)/$1 eq '-' ? '-' : ''/eg;
    $output->{identifier} = lc $title;
  }

  return $validation;
}

sub valid_durations { qw( 5 20 40 60 ) }

sub _load_sst {
  my $self = shift;
  my $key  = $self->id ? 'id' : 'identifier';

  <<"  SQL", map { $self->$_ } 'conference', $key;
    SELECT
      e.id,
      c.identifier as conference,
      c.name as conference_name,
      u.username as author,
      u.name as author_name,
      e.duration as duration,
      e.external_url as external_url,
      e.status as status,
      e.identifier as identifier,
      e.title as title,
      e.description as description,
      e.type as type
    FROM events e
    JOIN conferences c ON c.id=e.conference_id
    JOIN users u ON u.id=e.user_id
    WHERE
      c.identifier=?
      AND e.$key=?
  SQL
}

sub _insert_sst {
  my $self = shift;
  # http://sqlfiddle.com/#!15/e1168/1/3
  <<'  SQL', map { $self->$_ } qw( conference author duration identifier title description external_url type );
    INSERT INTO events (conference_id, user_id, duration, identifier, title, description, external_url, type)
    VALUES(
      (SELECT c.id FROM conferences c WHERE c.identifier=?),
      (SELECT u.id FROM users u WHERE u.username=?),
      ?, ?, ?, ?, ?, ?
    )
    RETURNING id
  SQL
}

sub _next_sequence { shift->sequence + 1 }

sub _update_sst {
  my $self = shift;
  <<'  SQL', map { $self->$_ } qw( identifier title description duration _next_sequence external_url type conference id );
    UPDATE events e
    SET identifier=?, title=?, description=?, duration=?, sequence=?, external_url=?, type=?
    FROM conferences c
    WHERE c.identifier=? AND e.id=?
  SQL
}

sub user_can_update {
  my ($self, $user) = @_;
  return 0 unless $user;
  return 1 unless $self->in_storage;
  $user = $user->username if UNIVERSAL::isa($user, 'MCT::Model::User');
  return $self->author eq $user ? 1 : 0;
}

sub TO_JSON {
  my $self = shift;
  return { map { ($_, $self->$_) } qw( identifier title description author author_name conference id ) };
}

1;
