use strict;
use warnings;
use Test::More;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";

{
    package Bax;
    use Moose;

    with qw/
        ExampleMooRoleWithAttribute
    /;


    has '+output_to' => (
        required => 1,
    );
}

ok 1;
done_testing;

