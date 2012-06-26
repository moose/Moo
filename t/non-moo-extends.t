use strict;
use warnings;
use Test::More;

{
    package ClassA;
    use Moo;

    has 'foo' => ( is => 'ro');
}

{
    package ClassB;
    our @ISA = 'ClassA';
}

package main;

my $o = ClassB->new;
isa_ok $o, 'ClassB';

done_testing;
