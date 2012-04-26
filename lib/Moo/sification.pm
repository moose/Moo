package Moo::sification;

use strictures 1;
use Devel::GlobalDestruction;

sub unimport { our $disarmed = 1 }

sub Moo::HandleMoose::AuthorityHack::DESTROY {
  unless (our $disarmed or in_global_destruction) {
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
