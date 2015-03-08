package MCT::Model::Presentation;

use Mojo::Base 'MCT::Model';

has abstract => '';
has author => '';
has author_name => '';
has conference => '';
has title => '';
has url_name => '';

sub _load_sst {
  my $self = shift;
  my $key  = $self->id ? 'id' : 'url_name';

  <<"  SQL", map { $self->$_ } 'conference', $key;
    SELECT
      p.id,
      c.identifier AS conference,
      u.username as author,
      u.name AS author_name,
      p.url_name,
      p.title,
      p.abstract
    FROM presentations p
    JOIN conferences c ON c.id=p.conference
    JOIN users u ON u.id=p.author
    WHERE
      c.identifier=?
      AND p.$key=?
  SQL
}

sub _insert_sst {
  my $self = shift;
  # http://sqlfiddle.com/#!15/e1168/1/3
  <<'  SQL', map { $self->$_ } qw( conference author url_name title abstract );
    INSERT INTO presentations (conference, author, url_name, title, abstract)
    VALUES(
      (SELECT c.id FROM conferences c WHERE c.identifier=?),
      (SELECT u.id FROM users u WHERE u.username=?),
      ?, ?, ?
    )
    RETURNING id
  SQL
}

sub _update_sst {
  my $self = shift;
  <<'  SQL', map { $self->$_ } qw( url_name title abstract conference id );
    UPDATE presentations p
    SET url_name=?, title=?, abstract=?
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
