use strictures 1;
use Test::More;
use Test::Fatal;

use Method::Generate::Constructor;
use Method::Generate::Accessor;

my $gen = Method::Generate::Constructor->new(
  accessor_generator => Method::Generate::Accessor->new
);

$gen->generate_method('Foo', 'new', {
  one => { },
  two => { init_arg => undef },
  three => { init_arg => 'THREE' }
});

my $first = Foo->new({
  one => 1,
  two => 2,
  three => -75,
  THREE => 3,
  four => 4,
});

is_deeply(
  { %$first }, { one => 1, three => 3 },
  'init_arg handling ok'
);

$gen->generate_method('Bar', 'new' => {
  one => { required => 1 },
  three => { init_arg => 'THREE', required => 1 }
});

like(
  exception { Bar->new },
  qr/Missing required arguments: THREE, one/,
  'two missing args reported correctly'
);

like(
  exception { Bar->new(THREE => 3) },
  qr/Missing required arguments: one/,
  'one missing arg reported correctly'
);

is(
  exception { Bar->new(one => 1, THREE => 3) },
  undef,
  'pass with both required args'
);

is(
  exception { Bar->new({ one => 1, THREE => 3 }) },
  undef,
  'hashrefs also supported'
);

is(
  exception { $first->new(one => 1, THREE => 3) },
  undef,
  'calling ->new on an object works'
);

like(
  exception { $gen->register_attribute_specs('seventeen'
      => { is => 'ro', init_arg => undef, required => 1 }) },
  qr/You cannot have a required attribute/,
  'required not allowed with init_arg undef'
);

is(
  exception { $gen->register_attribute_specs('eighteen'
      => { is => 'ro', init_arg => undef, required => 1, default => 'foo' }) },
  undef,
  'required allowed with init_arg undef if given a default'
);

done_testing;
