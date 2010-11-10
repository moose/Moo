use strictures 1;
use Test::More;

my @ran;

{
  package Foo; use Moo; sub BUILD { push @ran, 'Foo' }
  package Bar; use Moo; extends 'Foo'; sub BUILD { push @ran, 'Bar' }
  package Baz; use Moo; extends 'Bar';
  package Quux; use Moo; extends 'Baz'; sub BUILD { push @ran, 'Quux' }
}

{
  package Fleem;
  use Moo;
  extends 'Quux';
  has 'foo' => (is => 'ro');
  sub BUILD { push @ran, $_[0]->foo, $_[1]->{bar} }
}

my $o = Quux->new;

is(ref($o), 'Quux', 'object returned');
is_deeply(\@ran, [ qw(Foo Bar Quux) ], 'BUILDs ran in order');

@ran = ();

$o = Fleem->new(foo => 'Fleem1', bar => 'Fleem2');

is(ref($o), 'Fleem', 'object with inline constructor returned');
is_deeply(\@ran, [ qw(Foo Bar Quux Fleem1 Fleem2) ], 'BUILDs ran in order');

done_testing;
