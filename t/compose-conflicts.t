use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
  package MethodRole;
  use Moo::Role;
  sub method { __PACKAGE__ }
}

BEGIN {
  package MethodRole2;
  use Moo::Role;
  sub method { __PACKAGE__ }
}

BEGIN {
  package MethodClassOver;
  use Moo;
  sub method { __PACKAGE__ }
  with 'MethodRole';
}

BEGIN {
  is +MethodClassOver->new->method, 'MethodClassOver',
    'class methods override role methods';
}

BEGIN {
  package MethodRole2;
  use Moo::Role;
  has attr => (is => 'rw', coerce => sub { __PACKAGE__ } );
}

BEGIN {
  package MethodClassAndRoleAndRole;
  use Moo;
  with 'MethodRole';
  with 'MethodRole2';
}

BEGIN {
  my $o = 
  is +MethodClassAndRoleAndRole->new->method, 'MethodRole',
    'composed methods override later composed methods';
}

BEGIN {
  package MethodClassAndRoles;
  use Moo;
  ::like ::exception {
    with 'MethodRole', 'MethodRole2';
  }, qr/^Due to a method name conflict between roles/,
    'composing roles with conflicting methods fails';
}

BEGIN {
  package MethodRoleOver;
  use Moo::Role;
  sub method { __PACKAGE__ }
  with 'MethodRole';
}

BEGIN {
  package MethodClassAndRoleOver;
  use Moo;
  with 'MethodRoleOver';
}

BEGIN {
  is +MethodClassAndRoleOver->new->method, 'MethodRoleOver',
    'composing role methods override composed role methods';
}

BEGIN {
  package MethodClassOverAndRoleOver;
  use Moo;
  sub method { __PACKAGE__ }
  with 'MethodRoleOver';
}

BEGIN {
  is +MethodClassOverAndRoleOver->new->method, 'MethodClassOverAndRoleOver',
    'class methods override role and role composed methods';
}


BEGIN {
  package AttrRole;
  use Moo::Role;
  has attr => (is => 'rw', coerce => sub { __PACKAGE__ } );
}

BEGIN {
  package AttrClassOver;
  use Moo;
  has attr => (is => 'rw', coerce => sub { __PACKAGE__ });
  with 'AttrRole';
}

BEGIN {
  my $o = AttrClassOver->new(attr => 1);
  is $o->attr, 'AttrClassOver',
    'class attributes override role attributes in constructor';
  $o->attr(1);
  is $o->attr, 'AttrClassOver',
    'class attributes override role attributes in accessors';
}

BEGIN {
  package AttrRole2;
  use Moo::Role;
  has attr => (is => 'rw', coerce => sub { __PACKAGE__ } );
}

BEGIN {
  package AttrClassAndRoleAndRole;
  use Moo;
  with 'AttrRole';
  with 'AttrRole2';
}

BEGIN {
  my $o = AttrClassAndRoleAndRole->new(attr => 1);
  is $o->attr, 'AttrRole',
    'composed attributes override later composed attributes in constructor';
  $o->attr(1);
  is $o->attr, 'AttrRole',
    'composed attributes override later composed attributes in accessors';
}

BEGIN {
  package AttrClassAndRoles;
  use Moo;
  ::like ::exception {
    with 'AttrRole', 'AttrRole2';
  }, qr/^Due to a method name conflict between roles/,
    'composing roles with conflicting attributes fails';
}

BEGIN {
  package AttrRoleOver;
  use Moo::Role;
  has attr => (is => 'rw', coerce => sub { __PACKAGE__ });
  with 'AttrRole';
}

BEGIN {
  package AttrClassAndRoleOver;
  use Moo;
  with 'AttrRoleOver';
}

BEGIN {
  my $o = AttrClassAndRoleOver->new(attr => 1);
  is $o->attr, 'AttrRoleOver',
    'composing role attributes override composed role attributes in constructor';
  $o->attr(1);
  is $o->attr, 'AttrRoleOver',
    'composing role attributes override composed role attributes in accessors';
}

BEGIN {
  package AttrClassOverAndRoleOver;
  use Moo;
  has attr => (is => 'rw', coerce => sub { __PACKAGE__ });
  with 'AttrRoleOver';
}

BEGIN {
  my $o = AttrClassOverAndRoleOver->new(attr => 1);
  is $o->attr, 'AttrClassOverAndRoleOver',
    'class attributes override role and role composed attributes in constructor';
  $o->attr(1);
  is $o->attr, 'AttrClassOverAndRoleOver',
    'class attributes override role and role composed attributes in accessors';
}

done_testing;
