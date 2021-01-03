use strict;
use warnings;

use Test::More;

{
  package SubCon1;

  use Moo;

  has foo => (is => 'ro');

  package SubCon2;

  our @ISA = qw(SubCon1);
}

ok(SubCon2->new, 'constructor completes');

done_testing;
