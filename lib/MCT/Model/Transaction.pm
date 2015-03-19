package MCT::Model::Transaction;

use Mojo::Base -base;

use constant DEBUG => $ENV{MCT_MODEL_DEBUG} || 0;

has 'dbh';

sub DESTROY {
  return unless $_[0]->{rollback};
  my $self = shift;

  warn "[MCT::Model::Transaction] ROLLBACK\n" if DEBUG;

  for my $obj (@{$self->{track}||[]}) {
    my $last = delete $obj->{_last} or next;
    @$obj{keys %$last} = values %$last;
  }

  $self->dbh->rollback if $self->dbh;
}

sub commit {
  my $self = shift;

  if (delete $self->{rollback} and $self->dbh) {
    warn "[MCT::Model::Transaction] COMMIT\n" if DEBUG;
    $self->dbh->commit;
  }

  delete $_->{_last} for @{$self->{track}||[]};
  return $self;
}

sub new {
  my $self = shift->SUPER::new(@_, rollback => 1);
  warn "[MCT::Model::Transaction] BEGIN WORK\n" if DEBUG;
  $self->dbh->begin_work if $self->dbh;
  return $self;
}

sub track {
  my ($self, @objs) = @_;
  $_->{_last} ||= {} for @objs;
  push @{$self->{track}}, @objs;
  $self;
}

1;
