# this test is replicated to t/load_module.t for Moo::_Utils

use Moo::_strictures;
use Test::More;
use lib 't/lib';
use Role::Tiny ();
use InlineModule (
  'Foo::Bar' => q{
    package Foo::Bar;
    sub baz { 1 }
    1;
  },
);

{ package Foo::Bar::Baz; sub quux { } }

Role::Tiny::_load_module("Foo::Bar");

ok(eval { Foo::Bar->baz }, 'Loaded module ok');

done_testing;
