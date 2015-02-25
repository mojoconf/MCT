package MCT::Model;

use Mojo::Base -base;

use Mojo::IOLoop;
use Mojo::Pg;

has id => undef;
has pg => sub { Mojo::Pg->new };

sub in_storage { defined shift->id ? 1 : 0 }

sub load {
  my ($self, $cb) = @_;
  my $err;

  $cb ||= sub { $err = $_[1] };

  Mojo::IOLoop->delay(
    sub {
      $self->_query($self->_load_sst, shift->begin);
    },
    sub {
      my ($delay, $err, $results) = @_;
      die $err if $err;
      my $data = $results->hash;
      @$self{keys %$data} = values %$data;
      $self->$cb('') if $cb;
    },
  )->catch(sub{ $self->$cb($_[1]) })->wait;

  die $err if $err;
  return $self;
}

sub save {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my ($self, $attrs) = @_;
  my $method = $self->id ? '_update_sst' : '_insert_sst';
  my $err;

  $cb ||= sub { $err = $_[1] };

  Mojo::IOLoop->delay(
    sub {
      $self->$_($attrs->{$_}) for keys %$attrs;
      $self->_query($self->$method, shift->begin);
    },
    sub {
      my ($delay, $err, $results) = @_;
      die $err if $err;
      $self->id($results->hash->{id}) if $method eq '_insert_sst';
      $self->$cb('') if $cb;
    },
  )->catch(sub{ $self->$cb($_[1]) })->wait;

  die $err if $err;
  return $self;
}

sub _query {
  my ($self, $cb) = (shift, pop);
  my @args = @_;
  my $db = $self->pg->db;
  return $db->query(@args) unless $cb;
  Mojo::IOLoop->delay(
    sub { $db->query(@args, shift->begin) },
    sub {
      my ($delay, $err, $results) = @_;
      die $err if $err;
      $self->$cb(undef, $results);
    },
  )->catch(sub{ $self->$cb($_[1], undef) })->wait;
  return $self;
}

1;

