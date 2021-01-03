use strict;
use warnings;

use Test::More "$]" < 5.008009
  ? (skip_all => 'Mouse is broken on perl <= 5.8.8')
  : ();

{
  package Tower1;

  use Mouse;

  has 'attr1' => (is => 'ro', required => 1);

  package Tower2;

  use Moo;

  extends 'Tower1';

  has 'attr2' => (is => 'ro', required => 1);

  package Tower3;

  use Moose;

  extends 'Tower2';

  has 'attr3' => (is => 'ro', required => 1);

  __PACKAGE__->meta->make_immutable;

  package Tower4;
  use Moo;

  extends 'Tower1';

  has 'attr1' => (is => 'ro', required => 1);
  has 'attr2' => (is => 'ro', required => 1);
  has 'attr3' => (is => 'ro', required => 1);
  has 'attr4' => (is => 'ro', required => 1);
}

foreach my $num (1..4) {
  my $class = "Tower${num}";
  my @attrs = map "attr$_", 1..$num;
  my %args = map +($_ => "${_}_value"), @attrs;
  my $obj = $class->new(%args);
  is($obj->{$_}, "${_}_value", "Attribute $_ ok for $class") for @attrs;
  is Class::MOP::get_metaclass_by_name($class)->name, $class,
    'metaclass inflated correctly';
}

done_testing;
