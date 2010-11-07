use strictures 1;
use Test::More;
use Sub::Defer;

my %made;

my $one_defer = defer_sub 'Foo::one' => sub {
  die "remade - wtf" if $made{'Foo::one'};
  $made{'Foo::one'} = sub { 'one' }
};

my $two_defer = defer_sub 'Foo::two' => sub {
  die "remade - wtf" if $made{'Foo::two'};
  $made{'Foo::two'} = sub { 'two' }
};

is($one_defer, \&Foo::one, 'one defer installed');
is($two_defer, \&Foo::two, 'two defer installed');

is($one_defer->(), 'one', 'one defer runs');

is($made{'Foo::one'}, \&Foo::one, 'one made');

is($made{'Foo::two'}, undef, 'two not made');

is($one_defer->(), 'one', 'one (deferred) still runs');

is(Foo->one, 'one', 'one (undeferred) runs');

is(my $two_made = undefer_sub($two_defer), $made{'Foo::two'}, 'make two');

is($two_made, \&Foo::two, 'two installed');

is($two_defer->(), 'two', 'two (deferred) still runs');

is($two_made->(), 'two', 'two (undeferred) runs');

my $three = sub { 'three' };

is(undefer_sub($three), $three, 'undefer non-deferred is a no-op');

done_testing;
