package MCT::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;
  my $conference = $c->stash('conference');

  $c->delay(
    sub { $conference->presentations(shift->begin); },
    sub {
      my ($delay, $err, $presentations) = @_;
      die $err if $err;
      $c->stash(presentations => $presentations);
      $conference->attendees($delay->begin);
    },
    sub {
      my ($delay, $err, $attendees) = @_;
      die $err if $err;
      $c->render(attendees => $attendees);
    },
  );
}

sub is_admin {
  my $c = shift;
  my $user = $c->model->user(id => $c->session('uid'), conference => $c->stash('cid'));

  $c->stash(user => $user);
  $c->delay(
    sub { $user->load(shift->begin); },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->continue if $user->in_storage and $user->is_admin;
      return $c->redirect_to('user.profile');
    },
  );
}

1;
