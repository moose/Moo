use strictures;
use lib 'lib';
{
  package BaseClass;
  use Moo;
}
{
  package Subclass;
  use Moose;
  extends 'BaseClass';
  __PACKAGE__->meta->make_immutable;
}
{
  package Blorp;
  use Moo;
  extends 'Subclass';
}
our $o = Blorp->new;
