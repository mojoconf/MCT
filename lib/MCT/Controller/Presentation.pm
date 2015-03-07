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
      $c->render_not_authorized unless $c->can_update($p);
      $c->render('presentation/edit', p => $p);
    },
  );
}

sub store {
  my $c = shift;

  my $id = $c->param('id');
  my $p = $c->model->presentation(
    conference => $c->stash('conference')->identifier,
    $id ? (id => $id) : (),
  );

  my $title  = $c->param('title');
  my %set = (
    abstract => $c->param('abstract'),
    author   => $c->session('username'),
    subtitle => $c->param('subtitle'),
    title    => $title,
    url_name => $c->param('url_name') || $c->_url_name($title),
  );

  $c->delay(
    sub { $p->load(shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $c->render_not_authorized unless $c->can_update($p);
      $p->$_($set{$_}) for keys %set;
      $p->save($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $c->redirect_to(presentation => url_name => $p->url_name);
    },
  );
}

sub can_update {
  my ($c, $p) = @_;
  return 1 unless $p->in_storage;
  return $p->author == $c->session->{username};
}

sub render_not_authorized { shift->render(text => 'Not authorized', status => 401) }

sub _url_name {
  my ($c, $title) = @_;
  $title =~ s/\s/_/g;
  $title =~ s/\W//g;
  return lc $title;
}

1;

