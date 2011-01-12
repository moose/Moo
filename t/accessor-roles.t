use strictures 1;
use Test::More;
use Sub::Quote;

{
  package One; use Moo;
  has one => (is => 'ro', default => sub { 'one' });

  package One::P1; use Moo::Role;
  has two => (is => 'ro', default => sub { 'two' });

  package One::P2; use Moo::Role;
  has three => (is => 'ro', default => sub { 'three' });
}

my $combined = Moo::Role->create_class_with_roles('One', qw(One::P1 One::P2));
isa_ok $combined, "One";
ok $combined->does($_), "Does $_" for qw(One::P1 One::P2);

my $c = $combined->new;
is $c->one, "one",     "attr default set from class";
is $c->two, "two",     "attr default set from role";
is $c->three, "three", "attr default set from role";

done_testing;
