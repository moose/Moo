use strict;
use warnings;

use Test::More;

{
  package SomeObject;
  use Moo;
  use Sub::Defer qw(defer_sub);

  my $gen = 0;
  defer_sub 'SomeObject::deferred_sub' => sub {
    $gen++;
    sub { 1 };
  };

  after deferred_sub => sub {
    1;
  };

  ::is $gen, 1,
    'applying modifier undefers subs';


  my $gen_multi = 0;
  defer_sub 'SomeObject::deferred_sub_guff' => sub {
    $gen_multi++;
    sub { 1 };
  };

  defer_sub 'SomeObject::deferred_sub_wark' => sub {
    $gen_multi++;
    sub { 1 };
  };

  after [qw(deferred_sub_guff deferred_sub_wark)] => sub {
    1;
  };

  ::is $gen_multi, 2,
    'applying modifier to multiple subs undefers';
}

done_testing;
