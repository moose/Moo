use strict;
use warnings;
use lib 't/lib';

BEGIN {
  *CORE::GLOBAL::bless = sub {
    my $obj = CORE::bless( $_[0], (@_ > 1) ? $_[1] : CORE::caller() );

    $obj->isa("Foo");

    $obj;
  };
}
use Test::More;
use CaptureException;

use Moose ();

is exception {
  package SomeClass;
  use Moo;
}, undef, "isa call in bless override doesn't break Moo+Moose";

done_testing;
