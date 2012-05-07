use strictures 1;
use Test::More;

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
}

foreach my $num (1..3) {
  my $class = "Tower${num}";
  my @attrs = map "attr$_", 1..$num;
  my %args = map +($_ => "${_}_value"), @attrs;
  my $obj = $class->new(%args);
  is($obj->{$_}, "${_}_value", "Attribute $_ ok for $class") for @attrs;
}

done_testing;
