use t::Helper;

my $t = t::Helper->t(migrate_to => 6);
my $app = $t->app;

$app->model->conference(country => 'NO', name => 'mipre')->save;
$app->model->user(username => 'bruce', name => 'Bruce')->save;

$t->app->model->db->query(<<'SQL');
INSERT INTO presentations
  (conference_id, user_id, duration, url_name, title, abstract)
  VALUES(
    (SELECT c.id FROM conferences c WHERE c.identifier='mipre'),
    (SELECT u.id FROM users u WHERE u.username='bruce'),
    20, 'my-talk', 'My Talk', 'Too cool talk.'
  )
SQL

ok eval { $t->app->migrations->migrate }, 'migrate' or diag "migrate failed: $@";
my $p_new = $app->model->presentation(author => 'bruce', conference => 'mipre', identifier => 'my-talk')->load;
is $p_new->author, 'bruce', 'author';
is $p_new->author_name, 'Bruce', 'author_name';
is $p_new->description, 'Too cool talk.', 'description';
is $p_new->duration, '20', 'duration';
is $p_new->external_url, '', 'external_url';
is $p_new->identifier, 'my-talk', 'identifier';
is $p_new->start_time, undef, 'start_time';
is $p_new->status, 'TENTATIVE', 'status';
is $p_new->title, 'My Talk', 'title';
is $p_new->type, 'talk', 'type';

done_testing;
