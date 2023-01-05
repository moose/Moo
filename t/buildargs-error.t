use strict;
use warnings;
use lib 't/lib';

use Test::More;
use CaptureException;

{
    package Foo;
    use Moo;

    has bar => ( is => "rw" );
    has baz => ( is => "rw" );

    sub BUILDARGS {
        my ($self, $args) = @_;

        return %$args
    }
}

like(
  exception { Foo->new({ bar => 1, baz => 1 }) },
  qr/BUILDARGS did not return a hashref/,
  'Sensible error message'
);

done_testing;
