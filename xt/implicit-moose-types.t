use strict;
use warnings;

use Test::More;

use Moose::Util::TypeConstraints qw(find_type_constraint);

{
  package TestRole;
  use Moo::Role;
}

{
  package TestClass;
  use Moo;

  with 'TestRole';
}

my $o = TestClass->new;

foreach my $name (qw(TestClass TestRole)) {
  ok !find_type_constraint($name), "No $name constraint created without Moose loaded";
}
note "Loading Moose";
require Moose;

foreach my $name (qw(TestClass TestRole)) {
  my $tc = find_type_constraint($name);
  isa_ok $tc, 'Moose::Meta::TypeConstraint', "$name constraint"
    and ok $tc->check($o), "TestClass object passes $name constraint";
}

done_testing;
