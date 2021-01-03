use strict;
use warnings;

use Test::More;

{
  package Foo;

  use Moo;

  my @params = (is => 'ro', lazy => 1, default => sub { 3 });

  has one => (@params, predicate => 'has_one', clearer => 'clear_one');

  has $_ => (@params, clearer => 1, predicate => 1) for qw( bar _bar );
}

my $foo = Foo->new;

for ( qw( one bar _bar ) ) {
  my ($lead, $middle) = ('_' x /^_/, '_' x !/^_/);
  my $predicate = $lead . "has$middle$_";
  my $clearer   = $lead . "clear$middle$_";

  ok(!$foo->$predicate, 'empty');
  is($foo->$_, 3, 'lazy default');
  ok($foo->$predicate, 'not empty now');
  is($foo->$clearer, 3, 'clearer returns value');
  ok(!$foo->$predicate, 'clearer empties');
  is($foo->$_, 3, 'default re-fired');
  ok($foo->$predicate, 'not empty again');
}

done_testing;
