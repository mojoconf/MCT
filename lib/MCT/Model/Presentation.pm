package MCT::Model::Presentation;

use MCT::Model -row;
use Text::Markdown ();

my @VALID_STATUS = qw( waiting accepted rejected confirmed );

col abstract => '';
col duration => 20;
col status => 'waiting';
col title => '';
col url_name => '';

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
    UPDATE presentations p
    SET status=?
    FROM conferences c
    WHERE c.identifier=? AND p.url_name=?
  SQL

  Mojo::IOLoop->delay(
    sub { $self->_query($sql, $status, $self->conference, $self->url_name, shift->begin) },
    sub {
      my ($delay, $err, $res) = @_;
      $self->status($status) unless $err;
      $self->$cb($err);
    },
  )->catch(sub{ $self->$cb($_[1]) })->wait;

  return $self;
}

sub abstract_to_html {
  my ($self, $args) = @_;
  my $dom = Mojo::DOM->new(Text::Markdown::markdown($self->abstract));

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
  $validation->required('abstract');
  $validation->optional('url_name');

  my $output = $validation->output;
  if (my $title = $output->{title} and not $output->{url_name}) {
    $title =~ s/\s+/-/g;
    $title =~ s/(\W)/$1 eq '-' ? '-' : ''/eg;
    $output->{url_name} = lc $title;
  }

  return $validation;
}

sub _load_sst {
  my $self = shift;
  my $key  = $self->id ? 'id' : 'url_name';

  <<"  SQL", map { $self->$_ } 'conference', $key;
    SELECT
      p.id,
      c.identifier as conference,
      c.name as conference_name,
      u.username as author,
      u.name as author_name,
      p.duration,
      p.status,
      p.url_name,
      p.title,
      p.abstract
    FROM presentations p
    JOIN conferences c ON c.id=p.conference_id
    JOIN users u ON u.id=p.user_id
    WHERE
      c.identifier=?
      AND p.$key=?
  SQL
}

sub _insert_sst {
  my $self = shift;
  # http://sqlfiddle.com/#!15/e1168/1/3
  <<'  SQL', map { $self->$_ } qw( conference author duration url_name title abstract );
    INSERT INTO presentations (conference_id, user_id, duration, url_name, title, abstract)
    VALUES(
      (SELECT c.id FROM conferences c WHERE c.identifier=?),
      (SELECT u.id FROM users u WHERE u.username=?),
      ?, ?, ?, ?
    )
    RETURNING id
  SQL
}

sub _update_sst {
  my $self = shift;
  <<'  SQL', map { $self->$_ } qw( url_name title abstract duration conference id );
    UPDATE presentations p
    SET url_name=?, title=?, abstract=?, duration=?
    FROM conferences c
    WHERE c.identifier=? AND p.id=?
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
  return { map { ($_, $self->$_) } qw( url_name title abstract author author_name conference id ) };
}

1;
