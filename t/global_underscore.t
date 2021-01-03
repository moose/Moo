use strict;
use warnings;

use Test::More;
use lib 't/lib';
use InlineModule (
  'UnderscoreClass' => q{
    package UnderscoreClass;
    use Moo;
    with qw(UnderscoreRole);
    sub c1 { 'c1' };
    1;
  },
  'UnderscoreRole' => q{
    package UnderscoreRole;
    use Moo::Role;
    use ClobberUnderscore;
    sub r1 { 'r1' };
    1;
  },
  'ClobberUnderscore' => q{
    package ClobberUnderscore;
    sub h1 { 'h1' };
    undef $_;
    1;
  },
);

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
