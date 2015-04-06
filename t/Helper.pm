package t::Helper;
use Mojo::Base -base;

my $_test_table = sub {
  my $rows = pop;
  my $t = shift;
  my $selector = shift || 'table tbody';

  my $ri = 1;
  for my $r (@$rows) {
    my $ci = 1;
    for my $c (@$r) {
      my $q = "$selector tr:nth-of-type($ri) td:nth-of-type($ci)";
      if (ref $c eq 'ARRAY') {
        $t->text_is("$q $c->[0]", $c->[1]);
      }
      else {
        $t->text_is($q, $c);
      }
      $ci++;
    }
    $ri++;
  }

  return $t;
};

sub t {
  my ($class, %args) = @_;
  Test::More::plan(skip_all => "TEST_ONLINE=postgresql://@{[scalar getpwuid $<]}\@/mct_test") unless $ENV{TEST_ONLINE};
  $ENV{MCT_SKIP_MIGRATION} //= 1;
  $ENV{MCT_DATABASE_DSN} = $ENV{TEST_ONLINE};
  $ENV{MCT_MOCK} //= 1;
  my $t = Test::Mojo->new('MCT');
  $t->app->migrations->migrate(0)->migrate($args{migrate_to});
  $t;
}

sub import {
  my $class = shift;
  my $caller = caller;

  strict->import;
  warnings->import;

  eval <<"  CODE" or die $@;
  package $caller;
  use Mojo::Base -strict;
  use Test::More;
  use Test::Mojo;
  1;
  CODE

  no strict 'refs';
  *{"$caller\::_test_table"} = \$_test_table;
}

1;
