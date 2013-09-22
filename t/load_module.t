# this test is replicated to t/load_module_role_tiny.t for Role::Tiny

# work around RT#67692
use Moo::_Utils;
use strictures 1;

use Test::More;

use t::lib::INCModule;

local @INC = (sub {
  return unless $_[1] eq 'Foo/Bar.pm';
  inc_module("package Foo::Bar; sub baz { 1 } 1");
}, @INC);

{ package Foo::Bar::Baz; sub quux { } }

_load_module("Foo::Bar");

ok(eval { Foo::Bar->baz }, 'Loaded module ok');

done_testing;
