use strict;
use warnings;
use lib 't/lib';

use Test::More;
use CaptureException;

BEGIN {
  package Foo;
  use Moo;
  has one => (is => 'ro');
}

use Moo::HandleMoose;

require Moo::sification;

like exception { Moo::sification->unimport },
  qr/Can't disable Moo::sification after inflation has been done/,
  'Moo::sification can\'t be disabled after inflation';

done_testing;
