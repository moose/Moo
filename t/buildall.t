use strictures 1;
use Test::More;

my @ran;

{
  package Foo; use Class::Tiny; sub BUILD { push @ran, 'Foo' }
  package Bar; use Class::Tiny; extends 'Foo'; sub BUILD { push @ran, 'Bar' }
  package Baz; use Class::Tiny; extends 'Bar';
  package Quux; use Class::Tiny; extends 'Baz'; sub BUILD { push @ran, 'Quux' }
}

my $o = Quux->new;

is(ref($o), 'Quux', 'object returned');
is_deeply(\@ran, [ qw(Foo Bar Quux) ], 'BUILDs ran in order');

done_testing;
