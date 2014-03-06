package Moo::_mro;
use strictures 1;

if ($] >= 5.010) {
  require mro;
} else {
  require MRO::Compat;
}

1;
