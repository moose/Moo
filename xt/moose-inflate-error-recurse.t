use strictures 1;
use Test::More;
use Test::Fatal;

use Moose ();
BEGIN {
  package Role1;
  use Moo::Role;
  has attr1 => (is => 'ro', lazy => 1);
}
BEGIN {
  package Class1;
  use Moo;
  with 'Role1';
}
BEGIN {
  package SomeMooseClass;
  use Moose;
  ::like(
    ::exception { with 'Role1' },
    qr/You cannot have a lazy attribute/,
    'reasonable error rather than deep recursion for inflating invalid attr',
  );
}
done_testing;
