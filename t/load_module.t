use strictures 1;
use Test::More;
use Moo::_Utils;

local @INC = (sub {
  return unless $_[1] eq 'Foo/Bar.pm';
  my $source = "package Foo::Bar; sub baz { 1 } 1";
  open my $fh, '<', \$source;
  $fh;
}, @INC);

{ package Foo::Bar::Baz; sub quux { } }

_load_module("Foo::Bar");

ok(eval { Foo::Bar->baz }, 'Loaded module ok');

done_testing;
