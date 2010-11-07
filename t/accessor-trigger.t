use strictures 1;
use Test::More;

my @one_tr;

{
  package Foo;

  use Class::Tiny;

  has one => (is => 'rw', trigger => sub { push @one_tr, $_[1] });
}

my $foo = Foo->new;

ok(!@one_tr, "trigger not fired with no value");

$foo = Foo->new(one => 1);

is_deeply(\@one_tr, [ 1 ], "trigger fired on new");

my $res = $foo->one(2);

is_deeply(\@one_tr, [ 1, 2 ], "trigger fired on set");

is($res, 2, "return from set ok");

is($foo->one, 2, "return from accessor ok");

is_deeply(\@one_tr, [ 1, 2 ], "trigger not fired for accessor as get");

done_testing;
