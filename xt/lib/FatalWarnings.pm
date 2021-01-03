package FatalWarnings;
use strict;
use warnings;

sub import {
  $SIG{__WARN__} = sub { die @_ };
}

1;
