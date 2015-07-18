package Moo::sification;

use Moo::_strictures;
no warnings 'once';
use Devel::GlobalDestruction qw(in_global_destruction);

sub unimport {
  die "Can't disable Moo::sification after inflation has been done"
    if $Moo::HandleMoose::SETUP_DONE;
  our $disabled = 1;
}

sub Moo::HandleMoose::AuthorityHack::DESTROY {
  unless (our $disabled or in_global_destruction) {
    require Moo::HandleMoose;
    Moo::HandleMoose->import;
  }
}

sub import {
  return
    if our $setup_done;
  if ($INC{"Moose.pm"}) {
    require Moo::HandleMoose;
    Moo::HandleMoose->import;
  } else {
    $Moose::AUTHORITY = bless({}, 'Moo::HandleMoose::AuthorityHack');
  }
  $setup_done = 1;
}

1;
