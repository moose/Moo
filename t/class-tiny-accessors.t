use strictures 1;
use Test::More;

{
  package Foo;

  use Class::Tiny;

  has one => (is => 'ro');
  has two => (is => 'rw', init_arg => undef);
  has three => (is => 'ro', init_arg => 'THREE', required => 1);
}

my $foo = Foo->new(
  one => 1,
  THREE => 3
);

is_deeply(
  { %$foo }, { one => 1, three => 3 }, 'internals ok'
);

done_testing;
