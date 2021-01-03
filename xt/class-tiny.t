use strict;
use warnings;

use Test::More;
use Class::Tiny 1.001;

my %build;

{
  package MyClass;
  use Class::Tiny qw(name);
  sub BUILD {
    $build{+__PACKAGE__}++;
  }
}
{
  package MySubClass;
  use Moo;
  extends 'MyClass';
  sub BUILD {
    $build{+__PACKAGE__}++;
  }
  has 'attr1' => (is => 'ro');
}
MySubClass->new;

is $build{MyClass}, 1;
is $build{MySubClass}, 1;

done_testing;
