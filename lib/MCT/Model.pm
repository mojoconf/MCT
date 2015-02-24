package MCT::Model;

use Mojo::Base -base;

use Mojo::IOLoop;
use Mojo::Pg;

has pg => sub { Mojo::Pg->new };

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
}

1;

