use strictures 1;
use Test::More;

{
  package Foo;

  use Moo;

  has one => (is => 'ro');
  has two => (is => 'rw', init_arg => undef);
  has three => (is => 'ro', init_arg => 'THREE', required => 1);

  package Bar;

  use Moo::Role;

  has four => (is => 'ro');

  package Baz;

  use Moo;

  extends 'Foo';

  with 'Bar';

  has five => (is => 'rw');
}

my $foo = Foo->new(
  one => 1,
  THREE => 3
);

is_deeply(
  { %$foo }, { one => 1, three => 3 }, 'simple class ok'
);

my $baz = Baz->new(
  one => 1,
  THREE => 3,
  four => 4,
  five => 5,
);

is_deeply(
  { %$baz }, { one => 1, three => 3, four => 4, five => 5 },
  'subclass with role ok'
);

ok(eval { Foo->meta->make_immutable }, 'make_immutable returns true');
ok(!$INC{"Moose.pm"}, "Didn't load Moose");

done_testing unless caller;
