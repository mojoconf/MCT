use t::Helper;

my $t = t::Helper->t;
my $conference = $t->app->model->conference(name => 'Scheduler', country => 'DE')->save(sub {});

$t->get_ok('/user/connect?code=42')->status_is(302);
$t->get_ok('/scheduler/schedule.json')->status_is(200)
  ->json_is('/defaults', {})
  ->json_is('/properties/x_wr_caldesc', '')
  ->json_is('/properties/x_wr_calname', 'Scheduler')
  ->json_is('/properties/prodid', '-//MCT//NONSGML scheduler//EN')
  ->json_is('/events/0/start', '2015-06-04T09:00:00')
  ->json_is('/events/0/id', '1')
  ->json_is('/events/0/url', 'https://www.mojoconf.com/2015/events/1')
  ->json_is('/events/0/title', 'Non-blocking services with Mojolicious')
  ->json_is('/events/0/end', '2015-06-04T16:00:00');

$t->get_ok('/scheduler/schedule.ical')->status_is(200)
  ->content_like(qr{^BEGIN:VCALENDAR.*END:VCALENDAR}s)
  ->content_like(qr{^PRODID:-//MCT//NONSGML scheduler//EN}m)
  ->content_like(qr{^DTEND:20150604T160000}m)
  ->content_like(qr{^DTSTART:20150604T090000}m);

done_testing;
