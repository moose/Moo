use strict;
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
}
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

