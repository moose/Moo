use strict;
use warnings;
use Test::More;
use Moo ();

BEGIN {
  package Top;
  use Moo;
  has top => (is => 'ro', default => 1);
}

BEGIN {
  package Right;
  use Moo;
  extends 'Top';
  has right => (is => 'ro', default => 1);
}

BEGIN {
  package Left;
  use Moo;
  extends 'Top';
  has left => (is => 'ro', default => 1);
}

BEGIN {
  package Bottom;
  use Moo;
  use mro 'c3';
  extends 'Left', 'Right';
  has bottom => (is => 'ro', default => 1);
}

my $o = Bottom->new;

ok $o->top, 'has top level attrs';
ok $o->left, 'has left parent attrs';
ok $o->right, 'has right parent attrs';
ok $o->bottom, 'has bottom level attrs';

done_testing;
