use strictures 1;
use Test::More;

ok eval q{
  package Spoon;
  use Moo;

  has foo => ( is => 'ro' );

  no Moo;

  use Moo;

  has foo2 => ( is => 'ro' );

  no Moo;

  1;
}, "subs imported on 'use Moo;' after 'no Moo;'"
    or diag $@;

ok eval q{
  package Roller;
  use Moo::Role;

  has foo => ( is => 'ro' );

  no Moo::Role;

  use Moo::Role;

  has foo2 => ( is => 'ro' );

  no Moo::Role;

  1;
}, "subs imported on 'use Moo::Role;' after 'no Moo::Role;'"
    or diag $@;

done_testing;
