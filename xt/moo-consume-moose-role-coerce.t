use strict;
use warnings;
use Test::More;

{
    package RoleOne;
    use Moose::Role;
    use Moose::Util::TypeConstraints;
    use namespace::autoclean;

    subtype 'Foo', as 'Int';
    coerce 'Foo', from 'Str', via { 3 };

    has foo => (
        is => 'rw',
        isa => 'Foo',
        coerce => 1,
        clearer => '_clear_foo',
    );
}
{
    package Class;
    use Moo; # Works if use Moose..
    use namespace::clean -except => 'meta';

    with 'RoleOne';
}

my $i = Class->new( foo => 'bar' );
is $i->foo, 3;

done_testing;

