use strict;
use warnings;
use Test::More;

{
    package Foo;
    use Moo::Role;
    use namespace::autoclean;
}
{
    package Bar;
    use Moo::Role;
    use namespace::autoclean;

    has attr => (
        is => 'ro'
    );

    sub thing {}
}
{
    package Baz;
    use Moose;
    no Moose;

    ::ok(!__PACKAGE__->can('has'), 'No has function after no Moose;');
    Moose::with('Baz', 'Bar');
}

::is(Baz->can('thing'), Bar->can('thing'), 'Role copies method correctly');
::ok(Baz->can('attr'), 'Attr accessor correct');
::ok(!Baz->can('has'), 'Sugar not copied');

{
    package Bax;
    use Moose;
    with qw/
        Foo
        Bar
    /;
}

ok 1;
done_testing;

