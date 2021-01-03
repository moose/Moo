use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
  package MooParent;
  use Moo;
  has message => ( is => 'ro', required => 1 ),
}

BEGIN {
  package Child;
  use Moose;
  extends 'MooParent';
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
  package Role1;
  use Moo::Role;
}

BEGIN {
  package Role2;
  use Moose::Role;
}

BEGIN {
  package Class1;
  use Moo;
  with 'Role1';
}

BEGIN {
  package Class2;
  use Moose;
  extends 'Class1';
  with 'Role2';
}

ok +Class2->does('Role1'), "Moose child does parent's composed roles";
ok +Class2->does('Role2'), "Moose child does child's composed roles";

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
  with 'Role1';
}
BEGIN {
  package MooseChild;
  use Moose;
  extends 'MooChild';
  with 'Role2';
  has attr2 => (is => 'ro');
}

is exception { MooseChild->new }, undef, 'NonMoo->Moo->Moose(mutable) works';
MooseChild->meta->make_immutable(inline_constructor => 0);
is exception { MooseChild->new }, undef, 'NonMoo->Moo->Moose(immutable) works';

ok +MooseChild->does('Role2'), "Moose child does parent's composed roles with non-Moo ancestor";

done_testing;
