package TestEnv;
use strict;
use warnings;

sub import {
  $ENV{$_} = 1
    for grep defined && length, @_[1 .. $#_];
}

1;
