package MCT::Controller::Presentation;

use Mojo::Base 'Mojolicious::Controller';

sub show {
  my $c = shift;
  my $p = $c->model->presentation(
    conference => $c->stash('conference')->identifier,
    url_name   => $c->stash('url_name'),
  );
  $c->delay(
    sub { $p->load(shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $p->in_storage ? $c->render('presentation/show', p => $p) : $c->reply->not_found;
    },
  );
}

sub edit {
  my $c = shift;
  my $p = $c->model->presentation(
    conference => $c->stash('conference')->identifier,
    id   => $c->stash('url_name'),
  );

  $c->delay(
    sub { $p->load(shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->render_not_authorized unless $p->user_can_update($c->session('username'));
      $c->render('presentation/edit', p => $p);
    },
  );
}

sub store {
  my $c = shift;
  my $validation = $c->validation;

  my $id = $c->param('id');
  my $p = $c->model->presentation(
    conference => $c->stash('conference')->identifier,
    $id ? (id => $id) : (),
  );

  # if validation fails, render the edit page
  if ($p->validate($validation)->has_error) {
    return $c->render('presentation/edit', p => $p);
  }

  my $set = $validation->output;
  $set->{author} = $c->session('username');

  $c->delay(
    sub { $p->load(shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->render_not_authorized unless $p->user_can_update($c->session('username'));
      $p->save($set, $delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->render('presentation/edit', p => $p, saved => 1) if $id and !$c->param('view');
      return $c->redirect_to('presentation', url_name => $p->url_name);
    },
  );
}

sub render_not_authorized { shift->render(text => 'Not authorized', status => 401) }

1;

