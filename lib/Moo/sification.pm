package Moo::sification;

use strictures 1;

END { our $sky_falling = 1 }

sub Moo::HandleMoose::AuthorityHack::DESTROY {
  unless (our $sky_falling) {
    require Moo::HandleMoose;
    Moo::HandleMoose->import;
  }
}

if ($INC{"Moose.pm"}) {
  require Moo::HandleMoose;
  Moo::HandleMoose->import;
} else {
  $Moose::AUTHORITY = bless({}, 'Moo::HandleMoose::AuthorityHack');
}

1;
