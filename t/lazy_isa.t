use strictures 1;
use Test::More;
use Test::Fatal;

my $isa_called = 0;
{
  package FooISA;

  use Moo;

  my $isa = sub {
    $isa_called++;
    die "I want to die" unless $_[0] eq 'live';
  };

  has a_lazy_attr => (
    is => 'ro',
    isa => $isa,
    lazy => 1,
    builder => '_build_attr',
  );

  has non_lazy => (
    is => 'ro',
    isa => $isa,
    builder => '_build_attr',
  );

  sub _build_attr { 'die' }
}

ok my $lives = FooISA->new(a_lazy_attr=>'live', non_lazy=>'live'),
  'expect to live when both attrs are set to live in init';

my $called_pre = $isa_called;
$lives->a_lazy_attr;
is $called_pre, $isa_called, 'isa is not called on access when value already exists';

like(
  exception { FooISA->new(a_lazy_attr=>'live', non_lazy=>'die') },
  qr/I want to die/,
  'expect to die when non lazy is set to die in init',
);

like(
  exception { FooISA->new(a_lazy_attr=>'die', non_lazy=>'die') },
  qr/I want to die/,
  'expect to die when non lazy and lazy is set to die in init',
);

like(
  exception { FooISA->new(a_lazy_attr=>'die', non_lazy=>'live') },
  qr/I want to die/,
  'expect to die when lazy is set to die in init',
);

like(
  exception { FooISA->new() },
  qr/I want to die/,
  'expect to die when both lazy and non lazy are allowed to default',
);

like(
  exception { FooISA->new(a_lazy_attr=>'live') },
  qr/I want to die/,
  'expect to die when lazy is set to live but non lazy is allowed to default',
);

is(
  exception { FooISA->new(non_lazy=>'live') },
  undef,
  'ok when non lazy is set to something valid but lazy is allowed to default',
);

done_testing;
