package MCT::Controller::Conference;

use Mojo::Base 'Mojolicious::Controller';

sub create {
  my $c = shift;
  my $conference = $c->model->conference;
  my $validation = $c->validation;

  $c->stash(conference => $conference);

  if ($conference->validate($validation)->has_error) {
    return;
  }

  $c->delay(
    sub { $c->_find_latest_identifier(shift->begin) },
    sub {
      my ($delay, $err, $res) = @_;
      die $err if $err;
      return $c->reply->exception('TODO: Add support for creating more conferences') if $res->rows;
      return $conference->save($validation->output, shift->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->redirect_to(landing_page => cid => $conference->identifier);
    },
  );
}

sub load {
  my $c = shift;
  my $conference = $c->model->conference(identifier => $c->stash('cid'));

  $c->stash(conference => $conference);
  $c->delay(
    sub { $conference->load(shift->begin); },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      return $c->continue if $conference->in_storage;
      return $c->render('/conference/create');
    },
  );

  return;
}

sub landing_page {
  my $c = shift;

  $c->respond_to(
    json => {json => $c->stash('conference')},
    any => {},
  );
}

sub latest_conference {
  my $c = shift;

  $c->delay(
    sub { $c->_find_latest_identifier(shift->begin); },
    sub {
      my ($delay, $err, $res) = @_;
      die $err if $err;
      $res = $res->hash;
      return $c->redirect_to(landing_page => cid => $res->{identifier}) if $res;
      return $c->render('/conference/create', conference => $c->_default_conference);
    },
  );
}

sub page {
  my $c = shift;
  my $cid = $c->stash('cid');
  my $page = $c->stash('page');

  $c->render("$cid/$page");
}

sub _default_conference {
  shift->model->conference(
    analytics_code => 'UA-60226126-1',
    identifier => '2015',
    name => 'Mojoconf 2015',
    tagline => 'Be there or be square.',
  );
}

sub _find_latest_identifier {
  my ($c, $cb) = @_;
  $c->model->db->query('SELECT identifier FROM conferences ORDER BY created DESC LIMIT 1', $cb);
}

1;
