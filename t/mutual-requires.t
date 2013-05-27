use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Fatal;

is exception {
  package RoleA;
  use Moo::Role;
  requires 'method_b';
  requires 'attr_b';
  sub method_a {}
  has attr_a => (is => 'ro');
}, undef, 'define role a';

is exception {
  package RoleB;
  use Moo::Role;
  requires 'method_a';
  requires 'attr_a';
  sub method_b {}
  has attr_b => (is => 'ro');
}, undef, 'define role a';

is exception {
  package RoleC;
  use Moo::Role;
  with 'RoleA', 'RoleB';
  1;
}, undef, 'compose roles with mutual requires into role';

is exception {
  package PackageWithPrecomposed;
  use Moo;
  with 'RoleC';
  1;
}, undef, 'compose precomposed roles into package';

is exception {
  package PackageWithCompose;
  use Moo;
  with 'RoleA', 'RoleB';
  1;
}, undef, 'compose roles with mutual requires into package';

done_testing;
