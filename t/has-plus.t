use strictures 1;
use Test::More;
use Test::Fatal;

{
  package RollyRole;

  use Moo::Role;

  has f => (is => 'ro', default => sub { 0 });
}

{
  package ClassyClass;

  use Moo;

  has f => (is => 'ro', default => sub { 1 });
}

{
  package UsesTheRole;

  use Moo;

  with 'RollyRole';
}

{
  package UsesTheRole2;

  use Moo;

  with 'RollyRole';

  has '+f' => (default => sub { 2 });
}

{

  package ExtendsTheClass;

  use Moo;

  extends 'ClassyClass';

  has '+f' => (default => sub { 3 });
}

{
  package BlowsUp;

  use Moo;

  ::like(::exception { has '+f' => () }, qr/\Qhas '+f'/, 'Kaboom');
}

{
  package ClassyClass2;
  use Moo;
  has d => (is => 'ro', default => sub { 4 });
}

{
  package MultiClass;
  use Moo;
  extends 'ClassyClass', 'ClassyClass2';
  ::is(::exception {
    has '+d' => ();
    has '+f' => ();
  }, undef, 'extend attributes from multiple parents')
}

is(UsesTheRole->new->f, 0, 'role attr');
is(ClassyClass->new->f, 1, 'class attr');
is(UsesTheRole2->new->f, 2, 'role attr with +');
is(ExtendsTheClass->new->f, 3, 'class attr with +');

done_testing;
