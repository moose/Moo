use strictures 1;
use Test::More;

{
  package Spoon;

  use Moo;

  no warnings 'redefine';

  sub has { "has!" }

  no Moo;
}

ok(!Spoon->can('extends'), 'extends cleaned');
is(Spoon->has, "has!", 'has left alone');

done_testing;
