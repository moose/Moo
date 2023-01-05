use strict;
use warnings;
use lib 't/lib';

use Test::More;
use CaptureException;

{
  package Foo;
  use Moo;
  sub sub1 { 1 }
}
{
  package Bar;
  use Moose;
  ::is ::exception {
    has attr => (
      is => 'ro',
      isa => 'Foo',
      handles => qr/.*/,
    );
  }, undef, 'regex handles in Moose with Moo class isa';
}

done_testing;
