# this test is replicated to t/load_module.t for Moo::_Utils

use Role::Tiny ();
use strictures 1;
use Test::More;

local @INC = (sub {
  return unless $_[1] eq 'Foo/Bar.pm';
  my $source = "package Foo::Bar; sub baz { 1 } 1";
  open my $fh, '<', \$source;
  $fh;
}, @INC);

{ package Foo::Bar::Baz; sub quux { } }

Role::Tiny::_load_module("Foo::Bar");

ok(eval { Foo::Bar->baz }, 'Loaded module ok');

done_testing;
