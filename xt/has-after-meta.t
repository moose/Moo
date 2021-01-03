use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose ();

{
  package MyClass;
  use Moo;

  has attr1 => ( is => 'ro' );

  # this will inflate a metaclass and undefer all of the methods, including the
  # constructor.  the constructor still needs to be modifyable though.
  # Metaclass inflation can happen for unexpected reasons, such as using
  # namespace::autoclean (but only if Moose has been loaded).
  __PACKAGE__->meta->name;

  ::is ::exception {
    has attr2 => ( is => 'ro' );
  }, undef,
    'attributes can be added after metaclass inflation';
}

done_testing;
