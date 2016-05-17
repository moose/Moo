package FatalWarnings;
use strict;
use warnings;

sub import {
  $ENV{MOO_FATAL_WARNINGS} = 1;
}

1;
