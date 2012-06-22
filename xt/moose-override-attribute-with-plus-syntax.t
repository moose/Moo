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

is(
    MooseChild->new->foo,
    'MooseChild',
    'default value in Moose child'
);

done_testing;

