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

my $foo = Foo->new(one => 1);

is($foo->one, 1, 'ro reads');
$foo->one(-3) unless $Method::Generate::Accessor::CAN_HAZ_XS;
is($foo->one, 1, 'ro does not write');

is($foo->two, undef, 'rw reads');
$foo->two(-3);
is($foo->two, -3, 'rw writes');

done_testing;
