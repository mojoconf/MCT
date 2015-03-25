package MCT::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';

sub authorize {
  my $c = shift;
  my $uid = $c->session('uid') || -1;

  $c->delay(
    sub { $c->stash('conference')->has_role({id => $uid}, 'admin', shift->begin); },
    sub {
      my ($delay, $err, $has_role) = @_;
      die $err if $err;
      return $c->continue if $has_role;
      return $c->redirect_to('user.profile');
    },
  );
}

sub presentations {
  my $c = shift;

  $c->delay(
    sub { $c->stash('conference')->presentations(shift->begin); },
    sub {
      my ($delay, $err, $presentations) = @_;
      die $err if $err;
      $c->render(presentations => $presentations);
    },
  );
}

1;
