use Moo::_strictures;
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

done_testing;
