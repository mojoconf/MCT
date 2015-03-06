package MCT::Plugin::Mock;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Github;

our $user = {
  avatar_url => "https://github.com/images/error/octocat_happy.gif",
  email => 'john@example.com',
  gravatar_id => '',
  id => '42',
  login => 'john_gh',
  name => 'John Doe',
};

sub register {
  my ($self, $app, $config) = @_;

  $app->log->warn('[MCT_MOCK=1] Mocking interfaces.');

  Mojo::Util::monkey_patch('Mojo::Github', MOCKED => sub { 1 });
  Mojo::Util::monkey_patch('Mojo::Github', ua => sub { $app->ua });

  $app->defaults(oauth2_provider => 'mocked');
  $app->routes->get('/mocked/github/user')->to(cb => sub { shift->render(json => $user) });
}

1;
