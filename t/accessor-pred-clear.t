use strictures 1;
use Test::More;

{
  package Foo;

  use Moo;

  has one => (
    is => 'ro', lazy => 1, default => sub { 3 },
    predicate => 'has_one', clearer => 'clear_one'
  );
}

my $foo = Foo->new;

ok(!$foo->has_one, 'empty');
is($foo->one, 3, 'lazy default');
ok($foo->has_one, 'not empty now');
is($foo->clear_one, 3, 'clearer returns value');
ok(!$foo->has_one, 'clearer empties');
is($foo->one, 3, 'default re-fired');
ok($foo->has_one, 'not empty again');

done_testing;
