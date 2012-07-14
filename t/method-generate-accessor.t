use strictures 1;
use Test::More;
use Test::Fatal;

use Method::Generate::Accessor;

my $gen = Method::Generate::Accessor->new;

{
  package Foo;
  use Moo;
}

$gen->generate_method('Foo' => 'one' => { is => 'ro' });

$gen->generate_method('Foo' => 'two' => { is => 'rw' });

like(
  exception { $gen->generate_method('Foo' => 'three' => {}) },
  qr/Must have an is/, 'No is rejected'
);

like(
  exception { $gen->generate_method('Foo' => 'three' => { is => 'purple' }) },
  qr/Unknown is purple/, 'is purple rejected'
);

like(
  exception { $gen->generate_method('Foo' => 'four' => { is => 'ro', default => 5 }) },
  qr/Invalid default/, 'default - scalar rejected'
);

like(
  exception { $gen->generate_method('Foo' => 'five' => { is => 'ro', default => [] }) },
  qr/Invalid default/, 'default - arrayref rejected'
);

like(
  exception { $gen->generate_method('Foo' => 'five' => { is => 'ro', default => Foo->new }) },
  qr/Invalid default/, 'default - non-code-convertible object rejected'
);

is(
  exception { $gen->generate_method('Foo' => 'six' => { is => 'ro', default => sub { 5 } }) },
  undef, 'default - coderef accepted'
);

is(
  exception { $gen->generate_method('Foo' => 'seven' => { is => 'ro', default => bless sub { 5 } => 'Blah' }) },
  undef, 'default - blessed sub accepted'
);

{
  package WithOverload;
  use overload '&{}' => sub { sub { 5 } };
  sub new { bless {} }
}

is(
  exception { $gen->generate_method('Foo' => 'eight' => { is => 'ro', default => WithOverload->new }) },
  undef, 'default - object with overloaded ->() accepted'
);

like(
  exception { $gen->generate_method('Foo' => 'nine' => { is => 'ro', default => bless {} => 'Blah' }) },
  qr/Invalid default/, 'default - object rejected'
);

my $foo = Foo->new(one => 1);

is($foo->one, 1, 'ro reads');
ok(exception { $foo->one(-3) }, 'ro dies on write attempt');
is($foo->one, 1, 'ro does not write');

is($foo->two, undef, 'rw reads');
$foo->two(-3);
is($foo->two, -3, 'rw writes');

done_testing;
