use strict;
use warnings;
use Test::More;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";

{
    package ExampleRole;
    use Moo::Role;

    requires 'foo';

    with qw/
        ExampleMooseRoleOne
        ExampleMooseRoleTwo
    /;
}

{
    package ExampleClass;
    use Moose;

    with 'ExampleRole';

    sub foo {}
}

ok 1;

done_testing;

