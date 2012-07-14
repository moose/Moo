use strictures 1;
use Test::More;
use Test::Fatal;

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
