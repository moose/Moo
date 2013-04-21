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
{
    package MooChild;
    use Moo;
    extends 'MooParent';

    has '+foo' => (
        default => sub { 'MooChild' },
    );
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

is(exception {
    local $SIG{__WARN__} = sub { die $_[0] };
    ok(MooChild->meta->has_attribute('foo'), 'inflated metaclass has overridden attribute');
}, undef, 'metaclass inflation of plus override works without warnings');

done_testing;

