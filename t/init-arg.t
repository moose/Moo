use strictures 1;
use Test::More;
use Test::Fatal;

{
  package Foo;

  use Moo;

  has optional => (
    is => 'rw',
    init_arg => 'might_have',
    isa => sub { die "isa" if $_[0] % 2 },
    default => sub { 7 },
  );

  has lazy => (
    is => 'rw',
    init_arg => 'workshy',
    isa => sub { die "aieee" if $_[0] % 2 },
    default => sub { 7 },
    lazy => 1,
  );
}

like(
  exception { Foo->new },
  qr/\Aisa check for "optional" \(constructor argument: "might_have"\) failed:/,
  "isa default"
);

like(
  exception { Foo->new(might_have => 3) },
  qr/\Aisa check for "optional" \(constructor argument: "might_have"\) failed:/,
  "isa init_arg",
);

is(
  exception { Foo->new(might_have => 2) },
  undef, "isa init_arg ok"
);

my $foo = Foo->new(might_have => 2);

like(
  exception { $foo->optional(3) },
  qr/\Aisa check for "optional" failed:/,
  "isa accessor",
);

like(
  exception { $foo->lazy },
  qr/\Aisa check for "lazy" failed:/,
  "lazy accessor",
);

like(
  exception { $foo->lazy(3) },
  qr/\Aisa check for "lazy" failed:/,
  "lazy set isa fail",
);

is(
  exception { $foo->lazy(4) },
  undef,
  "lazy set isa ok",
);

like(
  exception { Foo->new(might_have => 2, workshy => 3) },
  qr/\Aisa check for "lazy" \(constructor argument: "workshy"\) failed:/,
  "lazy init_arg",
);

done_testing;
