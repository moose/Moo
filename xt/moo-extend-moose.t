use Moo::_strictures;
use Test::More;
use Test::Fatal;

BEGIN {
  package MooseRole;
  use Moose::Role;
  has attr_from_role => ( is => 'ro' );
}

BEGIN {
  package MooseParent;
  use Moose;
  with 'MooseRole';
  has attr_from_parent => ( is => 'ro' ),
}

BEGIN {
  package MooRole;
  use Moo::Role;
  has attr_from_role2 => ( is => 'ro' );
}

BEGIN {
  package MooChild;
  use Moo;
  extends 'MooseParent';
  with 'MooRole';
  has attr_from_child => ( is => 'ro' );
}

my $o = MooChild->new(
  attr_from_role => 1,
  attr_from_parent => 2,
  attr_from_role2 => 3,
  attr_from_child => 4,
);
is $o->attr_from_role, 1;
is $o->attr_from_parent, 2;
is $o->attr_from_role2, 3;
is $o->attr_from_child, 4;

ok +MooChild->meta->does_role('MooseRole');
ok +MooChild->does('MooseRole');

done_testing;
