package TestEnv;
use strict;
use warnings;

sub import {
  $ENV{$_} = 1
    for grep defined && length && !exists $ENV{$_}, @_[1 .. $#_];
  if ($ENV{MOO_FATAL_WARNINGS}) {
    my @opts = (
      '-Ixt/lib',
      '-MFatalWarnings',
      (exists $ENV{PERL5OPT} ? $ENV{PERL5OPT} : ()),
    );

    $ENV{PERL5OPT} = join ' ', @opts;
  }
}

1;
