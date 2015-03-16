BEGIN { $ENV{MOJO_MODE} = 'db_unittest' }
use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

eval {Test::Mojo->new('MCT')};
like $@, qr{mct_invalid_database_name;host=127\.0\.0\.255}, 'dsn from config';

done_testing;
