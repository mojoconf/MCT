package MCT::Model::User;

use Mojo::Base 'MCT::Model';
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

has address => '';
has city => '';
has country => '';
has email => '';
has name => '';
has t_shirt_size => '';
has username => sub { shift->email };
has web_page => '';

sub photo_url {
  my $self = shift;
  my $from = $self->photo_from or return '';
}

sub validate {
  my ($self, $validation, $cb) = @_;
  my $delay = Mojo::IOLoop->delay;

  $validation->optional('address');
  $validation->optional('city');
  $validation->optional('country');
  $validation->required('email')->match(qr{\@}); # poor mans email regex
  $validation->required('name')->match(qr{\w..});
  $validation->required('username')->match(qr{^...});
  $validation->optional('t_shirt_size')->in(qw( XS S M X L XL XXL ));
  $validation->optional('photo_id');
  $validation->optional('web_page');

  if (my $id = $validation->output->{photo_id}) {
    $validation->required('photo_from')->in(qw( twitter facebook github gravatar ));
    if (my $scheme = $validation->output->{photo_from}) {
      $validation->output->{photo_from} = "$scheme//$id";
    }
  }
  if (my $country = $validation->output->{country}) {
    my $cb = $delay->begin;
    $self->db->query('SELECT name FROM country WHERE id=?', $country, sub { $cb->($_[1]->rows or $validation->error(country => ['db'])) });
  }
  if (my $web_page = $validation->output->{web_page}) {
    my $cb = $delay->begin;
    $ua->get($web_page, sub { $cb->($_[1]->error and $validation->error(web_page => ['ua'])) });
  }

  $delay->on(finish => sub { $self->$cb('', $validation) });
  $delay->on(error => sub { $self->$cb($_[1], $validation) });
  $delay->pass('');

  return $self;
}

sub _load_sst {
  my $self = shift;
  my $key = $self->id ? 'id' : 'username';

  <<"  SQL", $self->$key;
    SELECT id, name, username, email
    FROM users
    WHERE $key=?
  SQL
}

sub _insert_sst {
  my $self = shift;
  <<'  SQL', map { $self->$_ } qw( name username email );
    INSERT INTO users (registered, name, username, email)
    VALUES (CURRENT_TIMESTAMP, ?, ?, ?)
    RETURNING id
  SQL
}

sub _update_sst {
  my $self = shift;
  <<"  SQL", map { $self->$_ } qw( name username email id );
    UPDATE users
    SET name=?, username=?, email=?
    WHERE id=?
  SQL
}

sub TO_JSON {
  my $self = shift;
  return { map { ($_, $self->$_) } qw( name username email id ) };
}

1;

