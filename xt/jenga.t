use strictures 1;
use Test::More;

{
  package Tower1;

  use Moo;

  has 'attr1' => (is => 'ro', required => 1);

  package Tower2;

  use Moose;

  extends 'Tower1';

  has 'attr2' => (is => 'ro', required => 1);

  __PACKAGE__->meta->make_immutable;

  package Tower3;

  use Moo;

  extends 'Tower2';

  has 'attr3' => (is => 'ro', required => 1);

  package Tower4;

  use Moose;

  extends 'Tower3';

  has 'attr4' => (is => 'ro', required => 1);

  __PACKAGE__->meta->make_immutable;
}

foreach my $num (1..4) {
  my $class = "Tower${num}";
  my @attrs = map "attr$_", 1..$num;
  my %args = map +($_ => "${_}_value"), @attrs;
  my $obj = $class->new(%args);
  is($obj->{$_}, "${_}_value", "Attribute $_ ok for $class") for @attrs;
}

done_testing;
