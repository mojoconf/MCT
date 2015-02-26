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
  $app->helper(get_token => sub { pop->(shift, 's3cret') });
  $app->routes->get('/mocked/eventbrite/v3/users/me')->to(cb => sub { shift->render(json => $user) });
}

1;
