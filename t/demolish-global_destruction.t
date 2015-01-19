use strictures 1;
no warnings 'once';
use Test::More tests => 2;
use POSIX ();
Test::More->builder->no_ending(1);

our $fail = 2;
BEGIN {
    package Foo;
    use Moo;

    sub DEMOLISH {
        my $self = shift;
        my ($igd) = @_;
        ::ok(
            !$igd,
            'in_global_destruction state is passed to DEMOLISH properly (false)'
        ) and $fail-- ;
    }
}

{
    my $foo = Foo->new;
}

END { $? = $fail }

BEGIN {
    package Bar;
    use Moo;

    sub DEMOLISH {
        my $self = shift;
        my ($igd) = @_;

        ::ok(
            $igd,
            'in_global_destruction state is passed to DEMOLISH properly (true)'
        ) and $fail--;
        POSIX::_exit($fail);
    }
}

our $bar = Bar->new;
