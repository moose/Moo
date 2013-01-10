use strictures 1;
use Test::More;
use Test::Fatal;

use Method::Generate::Accessor;
use Sub::Quote 'quote_sub';

my $gen = Method::Generate::Accessor->new;

{
  package Foo;
  use Moo;
}

{
  package WithOverload;
  use overload '&{}' => sub { sub { 5 } }, fallback => 1;
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

is(
  exception { $gen->generate_method('Foo' => 'ten' => { is => 'ro', builder => '_build_ten' }) },
  undef, 'builder - string accepted',
);

is(
  exception { $gen->generate_method('Foo' => 'eleven' => { is => 'ro', builder => sub {} }) },
  undef, 'builder - coderef accepted'
);

like(
  exception { $gen->generate_method('Foo' => 'twelve' => { is => 'ro', builder => 'build:twelve' }) },
  qr/Invalid builder/, 'builder - invalid name rejected',
);

is(
  exception { $gen->generate_method('Foo' => 'thirteen' => { is => 'ro', builder => 'build::thirteen' }) },
  undef, 'builder - fully-qualified name accepted',
);

is(
  exception { $gen->generate_method('Foo' => 'fifteen' => { is => 'lazy', builder => sub {15} }) },
  undef, 'builder - coderef accepted'
);

is(
  exception { $gen->generate_method('Foo' => 'sixteen' => { is => 'lazy', builder => quote_sub q{ 16 } }) },
  undef, 'builder - quote_sub accepted'
);

my $foo = Foo->new(one => 1);

is($foo->one, 1, 'ro reads');
ok(exception { $foo->one(-3) }, 'ro dies on write attempt');
is($foo->one, 1, 'ro does not write');

is($foo->two, undef, 'rw reads');
$foo->two(-3);
is($foo->two, -3, 'rw writes');

is($foo->fifteen, 15, 'builder installs code sub');
is($foo->_build_fifteen, 15, 'builder installs code sub under the correct name');

is($foo->sixteen, 16, 'builder installs quote_sub');

done_testing;
