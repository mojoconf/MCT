package MCT::Model::User;

use Mojo::Base 'MCT::Model';
use Crypt::Eksblowfish::Bcrypt ();

use constant BCRYPT_BASE_SETTINGS => do {
  my $cost = sprintf '%02i', 8;
  my $nul = 'a';
  join '', '$2', $nul, '$', $cost, '$';
};

has name => '';
has username => sub {
  my $self = shift;
  my $username = $self->email;
  $username =~ s!\W!-!g;
  $username;
};

has email => '';

sub password {
  my $self = shift;

  if ($_[0]) {
    $self->{password} = $self->_bcrypt($_[0]);
    return $self;
  }
  else {
    return $self->{password} // '';
  }
}

sub validate_password {
  my ($self, $plain) = @_;

  return 0 unless $self->password;
  return 1 if $self->_bcrypt($plain, $self->password) eq $self->password;
  return 0;
}

sub _bcrypt {
  my ($self, $plain, $settings) = @_;

  unless ($settings) {
    my $salt = join '', map { chr int rand 256 } 1 .. 16;
    $settings = BCRYPT_BASE_SETTINGS . Crypt::Eksblowfish::Bcrypt::en_base64($salt);
  }

  Crypt::Eksblowfish::Bcrypt::bcrypt($plain, $settings);
}

sub _load_sst {
  my $self = shift;
  <<'  SQL', $self->username;
    SELECT id, name, password, username, email
    FROM users
    WHERE username=?
  SQL
}

sub _insert_sst {
  my $self = shift;
  <<'  SQL', map { $self->$_ } qw( name password username email );
    INSERT INTO users (registered, name, password, username, email)
    VALUES (CURRENT_TIMESTAMP, ?, ?, ?, ?)
    RETURNING id
  SQL
}

sub _update_sst {
  my $self = shift;
  <<"  SQL", map { $self->$_ } qw( name password username email id );
    UPDATE users
    SET name=?, password=?, username=?, email=?
    WHERE id=?
  SQL
}

sub TO_JSON {
  my $self = shift;
  return { map { ($_, $self->$_) } qw( name username email id ) };
}

1;

