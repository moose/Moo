use strict;
use warnings;

use lib 't/lib';
use Test::More;

# this test is replicated to t/load_module_role_tiny.t for Role::Tiny

use Moo::_Utils qw(_load_module);
use InlineModule (
  'Foo::Bar' => q{
    package Foo::Bar;
    sub baz { 1 }
    1;
  },
  'BrokenModule' => q{
    package BrokenModule;
    use strict;
    sub guff { 1 }

    ;_;
  },
);

{ package Foo::Bar::Baz; sub quux { } }

_load_module("Foo::Bar");

ok(eval { Foo::Bar->baz }, 'Loaded module ok');

ok do { my $e; eval { _load_module("BrokenModule"); 1 } or $e = $@; $e },
  'broken module that installs subs gives error';

done_testing;
