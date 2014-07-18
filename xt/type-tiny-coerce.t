use strictures 1;
use Test::More;

{
  package Goo;
  use Moo;
  use Types::Standard qw(Int Num);

  has foo => (
    is      => 'ro',
    isa     => Int->plus_coercions(Num, q{ int($_) }),
    coerce  => 1,
  );
}

my $obj = Goo->new(
  foo => 3.14159,
);

is($obj->foo, '3', 'Type::Tiny coercion applied with coerce => 1');

done_testing;
