use Moo::_strictures;
use Test::More;

BEGIN {
  no warnings 'redefine';
  $INC{'Sub/Name.pm'} = 1;
  defined &Sub::Name::subname or *Sub::Name::subname = sub {};
  $INC{'Sub/Util.pm'} = 1;
  defined &Sub::Util::set_subname or *Sub::Util::set_subname = sub {};
}

use Moo::_Utils;

ok( Moo::_Utils::_CAN_SUBNAME,
  "_CAN_SUBNAME is true when both Sub::Name and Sub::Util are loaded"
);

done_testing;
