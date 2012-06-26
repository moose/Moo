use strictures 1;
use Test::More;

{
  package Spoon;

  use Moo;

  no warnings 'redefine';

  sub has { "has!" }

  no Moo;
}

{
  package Roller;

  use Moo::Role;

  no warnings 'redefine';

  sub with { "with!" }

  no Moo::Role;
}

ok(!Spoon->can('extends'), 'extends cleaned');
is(Spoon->has, "has!", 'has left alone');

ok(!Roller->can('has'), 'has cleaned');
is(Roller->with, "with!", 'with left alone');

done_testing;
