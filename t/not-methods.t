use strict;
use warnings;

use Test::More;

BEGIN {
  package FooClass;
  sub early { 1 }
  sub early_constant { 2 }
  use Moo;
  sub late { 2 }
  sub late_constant { 2 }
}

BEGIN {
  is_deeply
    [sort keys %{Moo->_concrete_methods_of('FooClass')}],
    [qw(late late_constant)],
    'subs created before use Moo are not methods';
}

BEGIN {
  package BarClass;
  sub early { 1 }
  use Moo;
  sub late { 2 }
  no warnings 'redefine';
  sub early { 3 }
}

BEGIN {
  is_deeply
    [sort keys %{Moo->_concrete_methods_of('BarClass')}],
    [qw(early late)],
    'only same subrefs created before use Moo are not methods';
}

BEGIN {
  package FooRole;
  sub early { 1 }
  use Moo::Role;
  sub late { 2 }
}

BEGIN {
  is_deeply
    [sort keys %{Moo::Role->_concrete_methods_of('FooRole')}],
    [qw(late)],
    'subs created before use Moo::Role are not methods';
}

BEGIN {
  package BarRole;
  sub early { 1 }
  use Moo::Role;
  sub late { 2 }
  no warnings 'redefine';
  sub early { 3 }
}

BEGIN {
  is_deeply
    [sort keys %{Moo::Role->_concrete_methods_of('BarRole')}],
    [qw(early late)],
    'only same subrefs created before use Moo::Role are not methods';
}

SKIP: {
  skip 'code refs directly in the stash not stable until perl 5.26.1', 1
    unless "$]" >= 5.026001;

  eval '#line '.(__LINE__).' "'.__FILE__.qq["\n].q{
    package Gwaf;
    BEGIN { $Gwaf::{foo} = sub { 'foo' }; }
    use constant plorp => 1;
    use Moo;
    BEGIN { $Gwaf::{frab} = sub { 'frab' }; }
    use constant terg => 1;
    1;
  } or die $@;

  is_deeply
    [sort keys %{Moo->_concrete_methods_of('Gwaf')}],
    [qw(frab terg)],
    'subrefs stored directly in stash treated the same as those with globs';
}

done_testing;
