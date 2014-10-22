use strict;
use warnings;
use Test::More;
use Test::Fatal;

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

BEGIN {
  package NonMooParent;
  sub new {
    bless {}, $_[0];
  }
}
BEGIN {
  package MooChild;
  use Moo;
  extends 'NonMooParent';
  has attr1 => (is => 'ro');
}
BEGIN {
  package MooseChild;
  use Moose;
  extends 'MooChild';
  has attr2 => (is => 'ro');
}

is exception { MooseChild->new }, undef, 'NonMoo->Moo->Moose(mutable) works';
MooseChild->meta->make_immutable;
is exception { MooseChild->new }, undef, 'NonMoo->Moo->Moose(immutable) works';

done_testing;
