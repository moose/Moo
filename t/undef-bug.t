use Test::More tests => 1;

package Foo;
use Moo;

has this => (is => 'ro');

package main;

my $foo = Foo->new;

ok not(exists($foo->{this})),
    "new objects don't have undef attributes";
