package Moo::_mro;
use strict;
use warnings;

if ("$]" >= 5.010_000) {
  require mro;
} else {
  require MRO::Compat;
}

1;
