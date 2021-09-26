use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package MyRole;
    use Moo::Role;
}
{
    package MyClass;
    use Moo;
    ::unlike ::exception { extends "MyRole"; }, qr/Can't extend role/;
}

done_testing;
