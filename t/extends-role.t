use strict;
use warnings;
use lib 't/lib';

use Test::More;
use CaptureException;

{
    package MyRole;
    use Moo::Role;
}
{
    package MyClass;
    use Moo;
    ::isnt ::exception { extends "MyRole"; }, undef, "Can't extend role";
}

done_testing;
