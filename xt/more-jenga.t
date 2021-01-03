use strict;
use warnings;

use Test::More;
use lib 't/lib';
use InlineModule (
  MooseRoleOne => q{
    package MooseRoleOne;
    use Moose::Role;
    1;
  },
  MooseRoleTwo => q{
    package MooseRoleTwo;
    use Moose::Role;
    1;
  },
);

{
  package MooRoleWithMooseRoles;
  use Moo::Role;

  requires 'foo';

  with qw/
    MooseRoleOne
    MooseRoleTwo
  /;
}

{
  package MooseClassWithMooRole;
  use Moose;

  with 'MooRoleWithMooseRoles';

  sub foo {}
}

ok 1, 'classes and roles built without error';

done_testing;
