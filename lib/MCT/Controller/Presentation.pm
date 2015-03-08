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
  return $c->render('presentation/edit')
    unless my $url_name = $c->stash('url_name');

  my $p = $c->model->presentation(
    conference => $c->stash('conference')->identifier,
    url_name   => $url_name,
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
      return $c->render_not_authorized unless $p->user_can_update($c->session('username'));
      $p->save(\%set, $delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $c->redirect_to(presentation => url_name => $p->url_name);
    },
  );
}

sub render_not_authorized { shift->render(text => 'Not authorized', status => 401) }

sub _url_name {
  my ($c, $title) = @_;
  $title =~ s/\s/_/g;
  $title =~ s/\W//g;
  return lc $title;
}

1;

