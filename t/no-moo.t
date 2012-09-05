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

{
  package NoMooClass;

  no warnings 'redefine';

  sub has { "has!" }

  my %stash = %{Moo::_Utils::_getstash(__PACKAGE__)};
  Moo->unimport;
  my %stash2 = %{Moo::_Utils::_getstash(__PACKAGE__)};
  main::is_deeply(\%stash, \%stash2, "stash of non-Moo class remains untouched");
}

{
  package GlobalConflict;

  use Moo;

  no warnings 'redefine';

  sub has { "has!" }

  no Moo;

  our $around = "has!";

  no Moo;
}

{
  package RollerTiny;

  use Role::Tiny;

  no warnings 'redefine';

  sub with { "with!" }

  my %stash = %{Moo::_Utils::_getstash(__PACKAGE__)};
  Moo::Role->unimport;
  my %stash2 = %{Moo::_Utils::_getstash(__PACKAGE__)};
  main::is_deeply(\%stash, \%stash2, "stash of non-Moo role remains untouched");
}

ok(!Spoon->can('extends'), 'extends cleaned');
is(Spoon->has, "has!", 'has left alone');

ok(!Roller->can('has'), 'has cleaned');
is(Roller->with, "with!", 'with left alone');

is(NoMooClass->has, "has!", 'has left alone');

ok(!GlobalConflict->can('extends'), 'extends cleaned');
is(GlobalConflict->has, "has!", 'has left alone');
{
  no warnings 'once';
  is($GlobalConflict::around, "has!", 'package global left alone');
}

ok(RollerTiny->can('around'), 'around left alone');
is(RollerTiny->with, "with!", 'with left alone');

done_testing;
