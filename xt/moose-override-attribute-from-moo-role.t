use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package MyRole;
    use Moo::Role;

    has foo => (
        is => 'ro',
        required => 1,
    );
}
{
    package MyClass;
    use Moose;

    with 'MyRole';

    has '+foo' => (
        isa => 'Str',
    );
}

is(
    exception { MyClass->new(foo => 'bar') },
    undef,
    'construct'
);
ok(
    exception { MyClass->new(foo => []) },
    'no construct, constraint works'
);
ok(
    exception { MyClass->new() },
    'no construct - require still works'
);

done_testing;

