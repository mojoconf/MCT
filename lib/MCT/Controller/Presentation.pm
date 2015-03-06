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

  my $title  = $c->param('title');
  my $p = $c->model->presentation(
    abstract   => $c->param('abstract'),
    author     => $c->session('username'),
    conference => $c->stash('conference')->identifier,
    subtitle   => $c->param('subtitle'),
    title      => $title,
    url_name   => $c->stash('url_name') || $c->param('url_name') || $c->_url_name($title),
  );
  $c->delay(
    sub { $p->save(shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $c->redirect_to(presentation => url_name => $p->url_name);
    },
  );
}

sub _url_name {
  my ($c, $title) = @_;
  $title =~ s/\s/_/g;
  $title =~ s/\W//g;
  return $title;
}

1;

