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

ok( Moo::_Utils::can_haz_subname || Moo::_Utils::can_haz_subutil,
  "one of can_haz_subname or can_haz_subutil set with both loaded"
);

done_testing;
