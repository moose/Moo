package Moo::sification;

use Moo::_strictures;
no warnings 'once';
BEGIN {
  *_USE_DGD = "$]" < 5.014 ? sub(){1} : sub(){0};
  require Devel::GlobalDestruction
    if _USE_DGD();
}
use Carp qw(croak);
BEGIN { our @CARP_NOT = qw(Moo::HandleMoose) }

sub unimport {
  croak "Can't disable Moo::sification after inflation has been done"
    if $Moo::HandleMoose::SETUP_DONE;
  our $disabled = 1;
}

sub Moo::HandleMoose::AuthorityHack::DESTROY {
  unless (our $disabled or
    _USE_DGD
      ? Devel::GlobalDestruction::in_global_destruction()
      : ${^GLOBAL_PHASE} eq 'DESTRUCT'
  ) {
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
