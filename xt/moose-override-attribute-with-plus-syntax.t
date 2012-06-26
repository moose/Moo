use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package MooParent;
    use Moo;

    has foo => (
        is => 'ro',
        default => sub { 'MooParent' },
    );
}
{
    package MooseChild;
    use Moose;
    extends 'MooParent';

    has '+foo' => (
        default => 'MooseChild',
    );
}
{
    package MooseChild2;
    use Moose;
    extends 'MooParent';

    has '+foo' => (
        default => 'MooseChild2',
    );
    __PACKAGE__->meta->make_immutable
}

is(
    MooseChild->new->foo,
    'MooseChild',
    'default value in Moose child'
);

is(
    MooseChild2->new->foo,
    'MooseChild2',
    'default value in Moose child'
);

done_testing;

