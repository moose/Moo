use strict;
use warnings;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use Test::More;

use_ok 'withautoclean::Class';

my $o = withautoclean::Class->new(_ctx => 1);
$o->_clear_ctx;
is $o->_ctx, undef, 'modified method works';

done_testing;
