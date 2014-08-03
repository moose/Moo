use strictures 1;
use Test::More;
use Test::Fatal;

use lib "t/lib";
use ComplexWriter;

sub run_for {
  my $class = shift;

  my $obj = $class->new(less_than_three => 1);

  is($obj->less_than_three, 1, "initial value set (${class})");

  like(
    exception { $obj->less_than_three(4) },
    qr/isa check for "less_than_three" failed: 4 is not less than three/,
    "exception thrown on bad set (${class})"
  );

  is($obj->less_than_three, 1, "initial value remains after bad set (${class})");

  my $ret;

  is(
    exception { $ret = $obj->less_than_three(2) },
    undef, "no exception on correct set (${class})"
  );

  is($ret, 2, "correct setter return (${class})");
  is($obj->less_than_three, 2, "correct getter return (${class})");

  is(exception { $class->new }, undef, "no exception with no value (${class})");
  like(
    exception { $class->new(less_than_three => 12) },
    qr/isa check for "less_than_three" failed: 12 is not less than three/,
    "exception thrown on bad constructor arg (${class})"
  );
}

{
  package Foo;

  use Moo;

  has less_than_three => (
    is => 'rw',
    isa => sub { die "$_[0] is not less than three" unless $_[0] < 3 }
  );
}

run_for 'Foo';

{
  package Bar;

  use Sub::Quote;
  use Moo;

  has less_than_three => (
    is => 'rw',
    isa => quote_sub q{
      my ($x) = @_;
      die "$x is not less than three" unless $x < 3
    }
  );
}

run_for 'Bar';

{
  package Baz;

  use Sub::Quote;
  use Moo;

  has less_than_three => (
    is => 'rw',
    isa => quote_sub(
      q{
        my ($value) = @_;
        die "$value is not less than ${word}" unless $value < $limit
      },
      { '$limit' => \3, '$word' => \'three' }
    )
  );
}

run_for 'Baz';

my $lt3;

{
  package LazyFoo;

  use Sub::Quote;
  use Moo;

  has less_than_three => (
    is => 'lazy',
    isa => quote_sub(q{ die "$_[0] is not less than three" unless $_[0] < 3 })
  );

  sub _build_less_than_three { $lt3 }
}

$lt3 = 4;

my $lazyfoo = LazyFoo->new;
like(
  exception { $lazyfoo->less_than_three },
  qr/isa check for "less_than_three" failed: 4 is not less than three/,
  "exception thrown on bad builder return value (LazyFoo)"
);

$lt3 = 2;

is(
  exception { $lazyfoo->less_than_three },
  undef,
  'Corrected builder value on existing object returned ok'
);

is(LazyFoo->new->less_than_three, 2, 'Correct builder value returned ok');

{
  package Fizz;

  use Moo;

  has attr1 => (
    is => 'ro',
    isa => sub {
      no warnings 'once';
      my $attr = $Method::Generate::Accessor::CurrentAttribute;
      die bless [@$attr{'name', 'init_arg', 'step'}], 'MyException';
    },
    init_arg => 'attr_1',
  );
}

my $e = exception { Fizz->new(attr_1 => 5) };
is(
  ref($e),
  'MyException',
  'Exception objects passed though correctly',
);

is($e->[0], 'attr1', 'attribute name available in isa check');
is($e->[1], 'attr_1', 'attribute init_arg available in isa check');
is($e->[2], 'isa check', 'step available in isa check');

{
  my $called;
  local $SIG{__DIE__} = sub { $called++; die $_[0] };
  my $e = exception { Fizz->new(attr_1 => 5) };
  ok($called, '__DIE__ handler called if set')
}

{
  package ClassWithDeadlyIsa;
  use Moo;
  has foo => (is => 'ro', isa => sub { die "nope" });

  package ClassUsingDeadlyIsa;
  use Moo;
  has bar => (is => 'ro', coerce => sub { ClassWithDeadlyIsa->new(foo => $_[0]) });
}

like exception { ClassUsingDeadlyIsa->new(bar => 1) },
  qr/isa check for "foo" failed: nope/,
  'isa check within isa check produces correct exception';

ComplexWriter->test_with("isa");

{
  package ClassWithEvilDestroy;
  sub new { bless {}, $_[0] }
  sub DESTROY {
    eval {
      # nop
    };
  }

  package ClassWithEvilException;
  use Moo;
  has foo => (is => 'rw', isa => sub {
    local $@;
    die "welp";
  });
  has bar => (is => 'rw', isa => sub {
    my $o = ClassWithEvilDestroy->new;
    die "welp";
  });
  my $error;
  has baz => (is => 'rw', isa => sub {
    ::is $@, $error, '$@ unchanged inside isa';
    1;
  });

  my $o = ClassWithEvilException->new;

  ::like ::exception { $o->foo(1) }, qr/isa check for "foo" failed:/,
    'got proper exception with localized $@';
  ::like ::exception { $o->bar(1) }, qr/isa check for "bar" failed:/,
    'got proper exception with eval in DESTROY';

  eval { die "blah\n" };
  $error = $@;
  $o->baz(1);
  ::is $@, $error, '$@ unchanged after successful isa';
}

done_testing;
