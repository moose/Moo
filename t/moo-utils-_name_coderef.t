use strict;
use warnings;

use Test::More;
use List::Util;   # List::Util provides Sub::Util::set_subname, so load it early
use Scalar::Util; # to make sure it doesn't warn about our fake subs

BEGIN {
  no warnings 'redefine';
  $INC{'Sub/Name.pm'} ||= 1;
  defined &Sub::Name::subname or *Sub::Name::subname = sub { $_[1] };
  $INC{'Sub/Util.pm'} ||= 1;
  defined &Sub::Util::set_subname or *Sub::Util::set_subname = sub { $_[1] };
}

use Moo::_Utils ();

ok( Moo::_Utils::_CAN_SUBNAME,
  "_CAN_SUBNAME is true when both Sub::Name and Sub::Util are loaded"
);

done_testing;
