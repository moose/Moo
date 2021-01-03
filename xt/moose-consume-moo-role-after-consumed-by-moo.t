use strict;
use warnings;

use Test::More;
use lib 't/lib';
use InlineModule (
  'MooRole' => q{
    package MooRole;
    use Moo::Role;

    $::MooRole_LOADED++;

    no Moo::Role;
    1;
  },
);

BEGIN { $::MooRole_LOADED = 0 }
BEGIN {
  package MooConsumer;
  use Moo;

  with "MooRole";
}
BEGIN {
  package MooseConsumer;
  use Moose;

  with "MooRole";
}

is $::MooRole_LOADED, 1, "role loaded only once";

done_testing;
