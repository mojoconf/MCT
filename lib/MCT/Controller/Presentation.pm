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

sub update {
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
      $c->render('presentation/edit', p => $p);
    },
  );
}

sub save {
  my $c = shift;

}

1;

