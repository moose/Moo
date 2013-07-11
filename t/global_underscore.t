use strict;
use warnings;
use Test::More;
use lib qw(t/lib);

use_ok('UnderscoreClass');

is(
  UnderscoreClass->c1,
  'c1',
);

is(
  UnderscoreClass->r1,
  'r1',
);

is(
  ClobberUnderscore::h1(),
  'h1',
);

done_testing;
