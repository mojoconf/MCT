package MCT::Plugin::Mock;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Eventbrite;

our $user = {
  emails => [
    { email => 'whatever@cpan.org', verified => 0, primary => 0 },
    { email => 'john@example.com', verified => 1, primary => 0 },
  ],
  id => 'whatever:123456789',
  name => 'John Doe',
  first_name => 'John',
  last_name => 'Doe',
};

sub register {
  my ($self, $app, $config) = @_;

  $app->log->warn('[MCT_MOCK=1] Mocking interfaces.');

  Mojo::Util::monkey_patch('Mojo::Eventbrite', MOCKED => sub { 1 });
  Mojo::Util::monkey_patch('Mojo::Eventbrite', ua => sub { $app->ua });
  Mojo::Util::monkey_patch('Mojolicious::Plugin::OAuth2', _ua => sub { $app->ua });

  $app->defaults(oauth2_provider => 'mocked');
  $app->routes->get('/mocked/eventbrite/v3/users/me')->to(cb => sub { shift->render(json => $user) });
  $app->routes->route('/mocked/oauth')
    ->tap(get => '/authorize' => sub { shift->render('mocked/oauth/authorize') })
    ->tap(post => '/token' => sub { shift->render(json => {access_token => 's3cret'}) });
}

1;
