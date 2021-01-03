use strict;
use warnings;

use lib 't/lib';
use InlineModule
  'Sub::Name' => undef,
  'Sub::Util' => undef,
;
use Test::More;

use Moo::_Utils ();

my $sub = Moo::_Utils::_subname 'Some::Sub', sub { 5 };
is $sub->(), 5, '_subname runs even without Sub::Name or Sub::Util';

done_testing;
