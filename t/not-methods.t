use Moo::_strictures;
use Test::More;

BEGIN {
  package FooClass;
  sub early { 1 }
  use Moo;
  sub late { 2 }
}

BEGIN {
  is_deeply
    [sort keys %{Moo->_concrete_methods_of('FooClass')}],
    [qw(late)],
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

done_testing;
