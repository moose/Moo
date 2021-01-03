use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Sub::Quote;

{
  package One; use Moo;
  has one => (is => 'ro', default => sub { 'one' });

  package One::P1; use Moo::Role;
  has two => (is => 'ro', default => sub { 'two' });

  package One::P2; use Moo::Role;
  has three => (is => 'ro', default => sub { 'three' });
  has four => (is => 'ro', lazy => 1, default => sub { 'four' }, predicate => 1);

  package One::P3; use Moo::Role;
  has '+three' => (is => 'ro', default => sub { 'three' });
}

my $combined = Moo::Role->create_class_with_roles('One', qw(One::P1 One::P2));
isa_ok $combined, "One";
ok $combined->does($_), "Does $_" for qw(One::P1 One::P2);
ok !$combined->does('One::P3'), 'Does not One::P3';

my $c = $combined->new;
is $c->one, "one",     "attr default set from class";
is $c->two, "two",     "attr default set from role";
is $c->three, "three", "attr default set from role";

{
  package Deux; use Moo; with 'One::P1';
  ::like(
    ::exception { has two => (is => 'ro', default => sub { 'II' }); },
    qr{^You cannot overwrite a locally defined method \(two\) with a reader},
    'overwriting accesssors with roles fails'
  );
}

{
  package Two; use Moo; with 'One::P1';
  has '+two' => (is => 'ro', default => sub { 'II' });
}

is(Two->new->two, 'II', "overwriting accessors using +attr works");

my $o = One->new;
Moo::Role->apply_roles_to_object($o, 'One::P2');
is($o->three, 'three', 'attr default set from role applied to object');
ok(!$o->has_four, 'lazy attr default not set on apply');

$o = $combined->new(three => '3');
Moo::Role->apply_roles_to_object($o, 'One::P3');
is($o->three, '3', 'attr default not used when already set when role applied to object');

done_testing;
