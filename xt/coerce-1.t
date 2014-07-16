use strictures 1;
use Test::More;
use Test::Requires { 'Types::Standard' => '0.008' };

{
  package IntConstraint;
  use Moo;
  use overload '&{}' => sub { shift->constraint }, fallback => 1;
  has constraint => (
    is       => 'ro',
    default  => sub {
      sub { $_[0] eq int $_[0] or die }
    },
  );
  sub check {
    my $self = shift;
    !!eval { $self->constraint->(@_); 1 }
  }
}

# First supported interface for coerce=>1.
# The type constraint provides an $isa->coerce($value) method.
{
  package IntConstraint::WithCoerceMethod;
  use Moo;
  extends qw(IntConstraint);
  sub coerce {
    my $self = shift;
    int($_[0]);
  }
}

# First supported interface for coerce=>1.
# The type constraint provides an $isa->coercion method
# providing a coderef such that $coderef->($value) coerces.
{
  package IntConstraint::WithCoercionMethod;
  use Moo;
  extends qw(IntConstraint);
  has coercion => (
    is       => 'ro',
    default  => sub {
      sub { int($_[0]) }
    },
  );
}

{
  package Goo;
  use Moo;
  use Types::Standard qw( ArrayRef Int Num );
  
  has foo => (
    is      => 'ro',
    isa     => Int->plus_coercions(Num, q{ int($_) }),
    coerce  => 1,
  );
  
  has bar => (
    is      => 'ro',
    isa     => IntConstraint::WithCoercionMethod->new,
    coerce  => 1,
  );
  
  has baz => (
    is      => 'ro',
    isa     => IntConstraint::WithCoerceMethod->new,
    coerce  => 1,
  );
}

my $obj = Goo->new(
  foo => 3.14159,
  bar => 3.14159,
  baz => 3.14159,
);

is($obj->foo, '3', 'Type::Tiny example');
is($obj->bar, '3', '$isa->coercion');
is($obj->baz, '3', '$isa->coerce');

done_testing;
