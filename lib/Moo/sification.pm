package Moo::sification;

use strictures 1;

sub Moo::HandleMoose::AuthorityHack::DESTROY {
  require Moo::HandleMoose;
  Moo::HandleMoose->import;
}

if ($INC{"Moose.pm"}) {
  require Moo::HandleMoose;
  Moo::HandleMoose->import;
} else {
  $Moose::AUTHORITY = bless({}, 'Moo::HandleMoose::AuthorityHack');
}

1;
