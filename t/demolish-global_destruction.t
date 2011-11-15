
use strictures 1;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moo;

    sub DEMOLISH {
        my $self = shift;
        my ($igd) = @_;
        ::ok(
            !$igd,
            'in_global_destruction state is passed to DEMOLISH properly (false)'
        );
    }
}

{
    my $foo = Foo->new;
}

chomp(my $out = `$^X t/global-destruction-helper.pl`);

is(
    $out, 'true',
    'in_global_destruction state is passed to DEMOLISH properly (true)'
);

done_testing;
