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

done_testing;
