BEGIN { delete $ENV{MOO_FATAL_WARNINGS} }
use strict;
use warnings;
use Test::More;

$INC{'strictures.pm'} = __FILE__;
my $strictures = 0;
my $version;
sub strictures::VERSION {
  $version = $_[1];
  2;;
}
sub strictures::import {
  $strictures++;
  strict->import;
  warnings->import(FATAL => 'all');
}

local $SIG{__WARN__} = sub {};
eval q{
  use Moo::_strictures;
  0 + "string";
};
is $strictures, 0, 'strictures not imported without MOO_FATAL_WARNINGS';
is $@, '', 'warnings not fatal without MOO_FATAL_WARNINGS';

$ENV{MOO_FATAL_WARNINGS} = 1;
eval q{
  use Moo::_strictures;
  0 + "string";
};
is $strictures, 1, 'strictures imported with MOO_FATAL_WARNINGS';
is $version, 2, 'strictures version 2 requested with MOO_FATAL_WARNINGS';
like $@, qr/isn't numeric/, 'warnings fatal with MOO_FATAL_WARNINGS';

done_testing;
