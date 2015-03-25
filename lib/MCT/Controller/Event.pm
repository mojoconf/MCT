package MCT::Controller::Event;

use Mojo::Base 'Mojolicious::Controller';

sub edit { shift->show('edit') }

sub show {
  my ($c, $edit) = @_;
  my $event = $c->stash('conference')->product(id => $c->param('id'));
  my @is_admin;

  # TODO: Should be a proper event object?

  if (my $uid = $c->session('uid')) {
    push @is_admin, sub { $c->stash('conference')->has_role({id => $uid}, 'admin', shift->begin); };
  }

  $c->delay(
    @is_admin,
    sub {
      my ($delay, $err, $is_admin) = @_;
      return $c->redirect_to('user.profile') if $edit and !$is_admin;
      $c->stash(is_admin => $is_admin);
      $event->load($delay->begin)
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $event->name ? $c->render(event => $event) : $c->reply->not_found;
    },
  );
}

sub store {
  my $c = shift;
  my $event = $c->stash('conference')->product(id => $c->param('id'));
  my $uid = $c->session('uid') || -1;
  my $validation = $c->validation;

  # if validation fails, render the edit page
  if ($event->validate($validation)->has_error) {
    return $c->render('event/edit', event => $event);
  }

  $c->delay(
    sub { $c->stash('conference')->has_role({id => $uid}, 'admin', shift->begin); },
    sub {
      my ($delay, $err, $is_admin) = @_;
      return $c->redirect_to('user.profile') unless $is_admin;
      $event->load($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $event->save($validation->output, $delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->render('event/edit', event => $event, saved => 1) unless $c->param('view');
      return $c->redirect_to('event.show');
    },
  );
}

1;
