use strict;
use warnings;

use Test::More;
use lib 't/lib';
use ErrorLocation;

use Moo::HandleMoose;

location_ok <<'END_CODE', 'Moo::sification::unimport - Moo::HandleMoose enabled';
use Moo::sification ();
Moo::sification->unimport;
END_CODE

location_ok <<'END_CODE', 'Moo::HandleMoose::inject_real_metaclass_for - Bad %TYPE_MAP value';
use Moo;
use Moo::HandleMoose ();
my $isa = sub { die "bad value" };
$Moo::HandleMoose::TYPE_MAP{$isa} = sub { return 1 };
has attr => (is => 'ro', isa => $isa);
$PACKAGE->meta->name;
END_CODE

{
  local $TODO = "croaks in roles don't skip consuming class";
location_ok <<'END_CODE', 'Moo::Role::_inhale_if_moose - isa from type';
BEGIN {
  eval qq{
    package ${PACKAGE}::Role;
    use Moose::Role;
    has attr1 => (is => 'ro', isa => 'HashRef');
    1;
  } or die $@;
}
use Moo;
with "${PACKAGE}::Role";
package Elsewhere;
$PACKAGE->new(attr1 => []);
END_CODE
}

done_testing;
