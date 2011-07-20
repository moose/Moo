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

{
  package Odd1;
  use Moo;
  has 'odd1' => (is => 'ro');
  sub BUILD { push @ran, 'Odd1' }
  package Odd2;
  use Moo;
  extends 'Odd1';
  package Odd3;
  use Moo;
  extends 'Odd2';
  has 'odd3' => (is => 'ro');
  sub BUILD { push @ran, 'Odd3' }
}

{
  package Sub1;
  use Moo;
  has 'foo' => (is => 'ro');
  package Sub2;
  use Moo;
  extends 'Sub1';
  sub BUILD { push @ran, "sub2" }
}

my $o = Quux->new;

is(ref($o), 'Quux', 'object returned');
is_deeply(\@ran, [ qw(Foo Bar Quux) ], 'BUILDs ran in order');

@ran = ();

$o = Fleem->new(foo => 'Fleem1', bar => 'Fleem2');

is(ref($o), 'Fleem', 'object with inline constructor returned');
is_deeply(\@ran, [ qw(Foo Bar Quux Fleem1 Fleem2) ], 'BUILDs ran in order');

@ran = ();

$o = Odd3->new(odd1 => 1, odd3 => 3);

is(ref($o), 'Odd3', 'Odd3 object constructed');
is_deeply(\@ran, [ qw(Odd1 Odd3) ], 'BUILDs ran in order');

@ran = ();

$o = Sub2->new;

is(ref($o), 'Sub2', 'Sub2 object constructed');
is_deeply(\@ran, [ qw(sub2) ], 'BUILD ran');

done_testing;
