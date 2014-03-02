use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moo::Role;
    # if we autoclean here there's nothing left and then load_class tries
    # to require Foo during Moose application and everything breaks.
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
::ok(!Bar->can('has'), 'Moo::Role sugar removed by autoclean');
::ok(!Bar->can('with'), 'Role::Tiny sugar removed by autoclean');
::ok(!Baz->can('has'), 'Sugar not copied');

{
    package Bax;
    use Moose;
    with qw/
        Foo
        Bar
    /;
}

{
    package Baw;
    use Moo::Role;
    has attr => (
        is => 'ro',
        traits => ['Array'],
        default => sub { [] },
        handles => {
            push_attr => 'push',
        },
    );
}
{
    package Buh;
    use Moose;
    with 'Baw';
}

is exception {
  Buh->new->push_attr(1);
}, undef, 'traits in role attributes are inflated properly';

{
    package Blorp;
    use Moo::Role;
    has attr => (is => 'ro');
}

is +Blorp->meta->get_attribute('attr')->name, 'attr',
  'role metaclass inflatable via ->meta';

done_testing;

