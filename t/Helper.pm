package t::Helper;
use Mojo::Base -base;

my $_test_table = sub {
  my ($t, $rows) = @_;

  my $ri = 1;
  for my $r (@$rows) {
    my $ci = 1;
    for my $c (@$r) {
      my $q = "table tbody tr:nth-of-type($ri) td:nth-of-type($ci)";
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

sub import {
  my $class = shift;
  my $caller = caller;

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
