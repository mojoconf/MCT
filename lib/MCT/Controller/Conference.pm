package MCT::Controller::Conference;

use Mojo::Base 'Mojolicious::Controller';

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
      return $c->reply->not_found;
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
      return $c->reply->not_found;
    },
  );
}

sub _find_latest_identifier {
  my ($c, $cb) = @_;
  $c->model->db->query('SELECT identifier FROM conferences ORDER BY created DESC LIMIT 1', $cb);
}

1;
