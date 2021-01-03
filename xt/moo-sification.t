use strict;
use warnings;

use Test::More;

BEGIN {
  package Foo;
  use Moo;
  has one => (is => 'ro');
}

no Moo::sification;
use Moose;
use Class::MOP;

is Class::MOP::get_metaclass_by_name('Foo'), undef,
  'no metaclass for Moo class after no Moo::sification';

done_testing;
