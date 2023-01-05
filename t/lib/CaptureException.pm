package CaptureException;
use strict;
use warnings;
use lib 't/lib';

use Exporter (); BEGIN { *import = \&Exporter::import }
use Carp ();

our @EXPORT = qw(exception);

sub exception (&) {
  my $cb = shift;
  eval {
    local $Test::Builder::Level = $Test::Builder::Level + 3;
    $cb->();
    1;
  } or do {
    return $@
      if $@;
    Carp::confess(
      (defined $@ ? 'false' : 'undef')
      . " exception caught by CaptureException::exception"
    );
  };
  return undef;
}

1;
