use strictures 1;
use Test::More;
use Test::Fatal;

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

like(
  exception { LazyFoo->new->less_than_three },
  qr/isa check for "less_than_three" failed: 4 is not less than three/,
  "exception thrown on bad builder return value (LazyFoo)"
);

$lt3 = 2;

is(LazyFoo->new->less_than_three, 2, 'Correct builder value returned ok');

done_testing;
