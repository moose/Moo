use strictures 1;
use Test::More;
use Test::Fatal;

use Method::Generate::Accessor;

my $gen = Method::Generate::Accessor->new;

{
  package Foo;
  use Moo;
}

{
  package WithOverload;
  use overload '&{}' => sub { sub { 5 } };
  sub new { bless {} }
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

for my $setting (qw( default coerce )) {
  like(
    exception { $gen->generate_method('Foo' => 'four' => { is => 'ro', $setting => 5 }) },
    qr/Invalid $setting/, "$setting - scalar rejected"
  );

  like(
    exception { $gen->generate_method('Foo' => 'five' => { is => 'ro', $setting => [] }) },
    qr/Invalid $setting/, "$setting - arrayref rejected"
  );

  like(
    exception { $gen->generate_method('Foo' => 'five' => { is => 'ro', $setting => Foo->new }) },
    qr/Invalid $setting/, "$setting - non-code-convertible object rejected"
  );

  is(
    exception { $gen->generate_method('Foo' => 'six' => { is => 'ro', $setting => sub { 5 } }) },
    undef, "$setting - coderef accepted"
  );

  is(
    exception { $gen->generate_method('Foo' => 'seven' => { is => 'ro', $setting => bless sub { 5 } => 'Blah' }) },
    undef, "$setting - blessed sub accepted"
  );

  is(
    exception { $gen->generate_method('Foo' => 'eight' => { is => 'ro', $setting => WithOverload->new }) },
    undef, "$setting - object with overloaded ->() accepted"
  );

  like(
    exception { $gen->generate_method('Foo' => 'nine' => { is => 'ro', $setting => bless {} => 'Blah' }) },
    qr/Invalid $setting/, "$setting - object rejected"
  );
}

my $foo = Foo->new(one => 1);

is($foo->one, 1, 'ro reads');
ok(exception { $foo->one(-3) }, 'ro dies on write attempt');
is($foo->one, 1, 'ro does not write');

is($foo->two, undef, 'rw reads');
$foo->two(-3);
is($foo->two, -3, 'rw writes');

done_testing;
