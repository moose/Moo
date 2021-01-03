use strict;
use warnings;

use Test::More "$]" < 5.008009
  ? (skip_all => 'Mouse is broken on perl <= 5.8.8')
  : ();

{
    package RoleOne;
    use Mouse::Role;
    use Mouse::Util::TypeConstraints;

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

    with 'RoleOne';
}

my $i = Class->new( foo => 'bar' );
is $i->foo, 3, 'coerce from type works';

done_testing;
