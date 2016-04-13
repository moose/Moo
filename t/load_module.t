# this test is replicated to t/load_module_role_tiny.t for Role::Tiny

use Moo::_strictures;
use Test::More;
use lib 't/lib';
use Moo::_Utils qw(_load_module);
use InlineModule (
  'Foo::Bar' => q{
    package Foo::Bar;
    sub baz { 1 }
    1;
  },
);

{ package Foo::Bar::Baz; sub quux { } }

_load_module("Foo::Bar");

ok(eval { Foo::Bar->baz }, 'Loaded module ok');

done_testing;
