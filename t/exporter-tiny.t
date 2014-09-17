use strictures 1;
use Test::More;

{
  package Foo;
  use Moo -default,
    has  => { is => "ro", -as => "has_ro" },
    has  => { is => "rw", -as => "has_rw" };
  
  has_ro foo => (is => "rw");
  has_rw bar => ();
  has_ro baz => ();
}

my $foo = Foo->new(foo => 111, bar => 222, baz => 333);
eval { $foo->foo(11) };
eval { $foo->bar(22) };
eval { $foo->baz(33) };

is($foo->foo, 11,  'has_ro with explicit is=>"rw"');
is($foo->bar, 22,  'has_rw with implicit is=>"rw"');
is($foo->baz, 333, 'has_ro with implicit is=>"ro"');

done_testing;
