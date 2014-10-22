use strict;
use warnings;
use Test::More;

BEGIN {
  package Parent;
  use Moo;
  has message => ( is => 'ro', required => 1 ),
}

BEGIN {
  package Child;
  use Moose;
  extends 'Parent';
  use Moose::Util::TypeConstraints;
  use namespace::clean;   # <-- essential
  has message => (
    is => 'ro', isa => 'Str',
    lazy => 1,
    default => sub { 'overridden message sub here' },
  );
}
# without namespace::clean, gives the (non-fatal) warning:
# You are overwriting a locally defined function (message) with an accessor
# ...because Moose::Util::TypeConstraints exports a 'message' sub!

my $obj = Child->new(message => 'custom message');

is($obj->message, 'custom message', 'accessor works');

done_testing;
