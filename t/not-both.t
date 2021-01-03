use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moo ();
use Moo::Role ();

{
  like exception {
    package ZZZ;
    Role::Tiny->import;
    Moo->import;
  }, qr{Cannot import Moo into a role},
    "can't import Moo into a Role::Tiny role";
}

{
  like exception {
    package XXX;
    Moo->import;
    Moo::Role->import;
  }, qr{Cannot import Moo::Role into a Moo class},
    "can't import Moo::Role into a Moo class";
}

{
  like exception {
    package YYY;
    Moo::Role->import;
    Moo->import;
  }, qr{Cannot import Moo into a role},
    "can't import Moo into a Moo role";
}

{
  is exception {
    package FFF;
    $Moo::MAKERS{+__PACKAGE__} = {};
    Moo::Role->import;
  }, undef,
    "Moo::Role can be imported into a package with fake MAKERS";
}

done_testing;
