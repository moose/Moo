use strictures;

package load_module_error;

use Test::More;

use lib 't/lib';

eval "use sub_class;";

ok $@, "got a crash";
unlike $@, qr/Unknown error/, "it came with a useful error message";

done_testing;
