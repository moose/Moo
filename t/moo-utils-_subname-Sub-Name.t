use strict;
use warnings;

use lib 't/lib';
use InlineModule
  'Sub::Name' => <<'END_SN',
package Sub::Name;
use strict;
use warnings;

sub subname {
  $::sub_name_run++;
  return $_[1];
}

1;
END_SN
  'Sub::Util' => undef,
;
use Test::More;

use Moo::_Utils ();

$::sub_name_run = 0;
my $sub = Moo::_Utils::_subname 'Some::Sub', sub { 5 };
is $sub->(), 5, '_subname runs with Sub::Name';
is $::sub_name_run, 1, '_subname uses Sub::Name::subname';

done_testing;
