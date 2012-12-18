use strictures;
use Test::More;
use lib 'xt/lib';

BEGIN { $::ExampleMooRole_LOADED = 0 }
BEGIN {
    package ExampleMooConsumer;
    use Moo;

    with "ExampleMooRole";
}
BEGIN {
    package ExampleMooseConsumer;
    use Moose;

    with "ExampleMooRole";
}

is $::ExampleMooRole_LOADED, 1, "role loaded only once";

done_testing;
