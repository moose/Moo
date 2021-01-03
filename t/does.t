use strict;
use warnings;

use Test::More;

BEGIN {
  package TestParent;
  use Moo;
}

BEGIN {
  package TestClass;
  use Moo;
  extends 'TestParent';

  has attr1 => (is => 'ro');
}

BEGIN {
  ok !TestClass->does('TestRole'),
    "->does returns false for arbitrary role";
  ok !$INC{'Moo/Role.pm'},
    "Moo::Role not loaded by does";
}

BEGIN {
  package TestRole;
  use Moo::Role;

  has attr2 => (is => 'ro');
}

BEGIN {
  package TestClass;
  with 'TestRole';
}

BEGIN {
  ok +TestClass->does('TestRole'),
    "->does returns true for composed role";

  ok +TestClass->DOES('TestRole'),
    "->DOES returns true for composed role";

  ok +TestClass->DOES('TestParent'),
    "->DOES returns true for parent class";
}

done_testing;
