use Moo::_strictures;
use Test::More;
use Test::Fatal;
use Sub::Defer qw(defer_sub undefer_sub undefer_all undefer_package);

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

like exception { defer_sub 'welp' => sub { sub { 1 } } },
  qr/^welp is not a fully qualified sub name!/;
  'correct error for defer_sub with unqualified name';

is(my $two_made = undefer_sub($two_defer), $made{'Foo::two'}, 'make two');

is exception { undefer_sub($two_defer) }, undef,
  "repeated undefer doesn't regenerate";

is($two_made, \&Foo::two, 'two installed');

is($two_defer->(), 'two', 'two (deferred) still runs');

is($two_made->(), 'two', 'two (undeferred) runs');

my $three = sub { 'three' };

is(undefer_sub($three), $three, 'undefer non-deferred is a no-op');

my $four_defer = defer_sub 'Foo::four' => sub {
  sub { 'four' }
};
is($four_defer, \&Foo::four, 'four defer installed');

# somebody somewhere wraps up around the deferred installer
no warnings qw/redefine/;
my $orig = Foo->can('four');
*Foo::four = sub {
  $orig->() . ' with a twist';
};

is(Foo->four, 'four with a twist', 'around works');
is(Foo->four, 'four with a twist', 'around has not been destroyed by first invocation');

my $one_all_defer = defer_sub 'Foo::one_all' => sub {
  $made{'Foo::one_all'} = sub { 'one_all' }
};

my $two_all_defer = defer_sub 'Foo::two_all' => sub {
  $made{'Foo::two_all'} = sub { 'two_all' }
};

is( $made{'Foo::one_all'}, undef, 'one_all not made' );
is( $made{'Foo::two_all'}, undef, 'two_all not made' );

undefer_all();

is( $made{'Foo::one_all'}, \&Foo::one_all, 'one_all made by undefer_all' );
is( $made{'Foo::two_all'}, \&Foo::two_all, 'two_all made by undefer_all' );

defer_sub 'Bar::one' => sub {
  $made{'Bar::one'} = sub { 'one' }
};
defer_sub 'Bar::two' => sub {
  $made{'Bar::two'} = sub { 'two' }
};
defer_sub 'Bar::Baz::one' => sub {
  $made{'Bar::Baz::one'} = sub { 'one' }
};

undefer_package('Bar');

is( $made{'Bar::one'}, \&Bar::one, 'one made by undefer_package' );
is( $made{'Bar::two'}, \&Bar::two, 'two made by undefer_package' );

is( $made{'Bar::Baz::one'}, undef, 'sub-package not undefered by undefer_package' );

{
  my $foo = defer_sub undef, sub { sub { 'foo' } };
  my $foo_string = "$foo";
  undef $foo;

  is Sub::Defer::defer_info($foo_string), undef,
    "deferred subs don't leak";

  Sub::Defer->CLONE;
  ok !exists $Sub::Defer::DEFERRED{$foo_string},
    'CLONE cleans out expired entries';
}

{
  my $foo = defer_sub undef, sub { sub { 'foo' } };
  my $foo_string = "$foo";
  Sub::Defer->CLONE;
  undef $foo;

  is Sub::Defer::defer_info($foo_string), undef,
    "CLONE doesn't strengthen refs";
}

{
  my $foo = defer_sub undef, sub { sub { 'foo' } };
  my $foo_string = "$foo";
  my $foo_info = Sub::Defer::defer_info($foo_string);
  undef $foo;

  is exception { Sub::Defer->CLONE }, undef,
    'CLONE works when quoted info saved externally';
  ok exists $Sub::Defer::DEFERRED{$foo_string},
    'CLONE keeps entries that had info saved externally';
}

{
  my $foo = defer_sub undef, sub { sub { 'foo' } };
  my $foo_string = "$foo";
  my $foo_info = $Sub::Defer::DEFERRED{$foo_string};
  undef $foo;

  is exception { Sub::Defer->CLONE }, undef,
    'CLONE works when quoted info kept alive externally';
  ok !exists $Sub::Defer::DEFERRED{$foo_string},
    'CLONE removes expired entries that were kept alive externally';
}

{
  my $foo = defer_sub undef, sub { sub { 'foo' } };
  my $foo_string = "$foo";
  undef $foo;
  Sub::Defer::undefer_package 'Unused';
  is exception { undefer_sub $foo_string }, undef,
    "undeferring expired sub (or reused refaddr) after undefer_package lives";
}

done_testing;
