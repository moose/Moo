use strict;
use warnings;

use Test::More;

{
    package RoleOne;
    use Moose::Role;

    has foo => ( is => 'rw' );
}

{
    package RoleTwo;
    use Moose::Role;

    has bar => ( is => 'rw' );
}

{
    package SomeClass;
    use Moo;

    with 'RoleOne', 'RoleTwo';
}

my $i = SomeClass->new( foo => 'bar', bar => 'baz' );
is $i->foo, 'bar', "attribute from first role is correct";
is $i->bar, 'baz', "attribute from second role is correct";

done_testing;
