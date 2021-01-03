use strict;
use warnings;

use Test::More;

{
    package ExampleRole;
    use Moo::Role;
}

{
    package ExampleClass;
    use Moose;

    with 'ExampleRole';
}

ok 1;

done_testing;
