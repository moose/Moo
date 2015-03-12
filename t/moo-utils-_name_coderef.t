use Test::More;

local $INC{'Sub/Name.pm'} = 1;
local $INC{'Sub/Util.pm'} = 1;

require Moo::_Utils;

ok( Moo::_Utils->can_haz_subname || Moo::_Utils->can_haz_subutil,
    "one of can_haz_subname or can_haz_subutil set with both loaded"
);

done_testing;

