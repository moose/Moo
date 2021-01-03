use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
  package ClassBakedNew;
  use Moo;

  has attr1 => (is => 'ro');
  __PACKAGE__->new;

  ::like ::exception {
    has attr2 => (is => 'ro');
  }, qr/Constructor for ClassBakedNew has been inlined/,
    'error when adding attributes with undeferred constructor';
}

BEGIN {
  package ClassExistingNew;
  use Moo;
  no warnings 'once';

  sub new {
    our $CALLED++;
    bless {}, $_[0];
  }

  ::like ::exception {
    has attr1 => (is => 'ro');
  }, qr/Unknown constructor for ClassExistingNew already exists/,
    'error when adding attributes with foreign constructor';
}

BEGIN {
  package ClassDeferredNew;
  use Moo;
  no warnings 'once';
  use Sub::Quote;

  quote_sub __PACKAGE__ . '::new' => q{
    our $CALLED++;
    bless {}, $_[0];
  };

  ::like ::exception {
    has attr1 => (is => 'ro');
  }, qr/Unknown constructor for ClassDeferredNew already exists/,
    'error when adding attributes with foreign deferred constructor';
}

BEGIN {
  package ClassWithModifier;
  use Moo;
  no warnings 'once';

  has attr1 => (is => 'ro');

  around new => sub {
    our $CALLED++;
    my $orig = shift;
    goto $orig;
  };

  ::like ::exception {
    has attr2 => (is => 'ro');
  }, qr/Constructor for ClassWithModifier has been replaced with an unknown sub/,
    'error when adding attributes after applying modifier to constructor';
}

BEGIN {
  package Role1;
  use Moo::Role;

  has attr1 => (is => 'ro');
}

BEGIN {
  package ClassWithRoleAttr;
  use Moo;
  no warnings 'once';

  around new => sub {
    our $CALLED++;
    my $orig = shift;
    goto $orig;
  };


  ::like ::exception {
    with 'Role1';
  }, qr/Unknown constructor for ClassWithRoleAttr already exists/,
    'error when adding role with attribute after applying modifier to constructor';
}


BEGIN {
  package RoleModifyNew;
  use Moo::Role;
  no warnings 'once';

  around new => sub {
    our $CALLED++;
    my $orig = shift;
    goto $orig;
  };
}

BEGIN {
  package ClassWithModifyRole;
  use Moo;
  no warnings 'once';
  with 'RoleModifyNew';

  ::like ::exception {
    has attr1 => (is => 'ro');
  }, qr/Unknown constructor for ClassWithModifyRole already exists/,
    'error when adding attributes after applying modifier to constructor via role';
}

BEGIN {
  package AClass;
  use Moo;
  has attr1 => (is => 'ro');
}

BEGIN {
  package ClassWithParent;
  use Moo;

  has attr2 => (is => 'ro');
  __PACKAGE__->new;

  ::like ::exception {
    extends 'AClass';
  }, qr/Constructor for ClassWithParent has been inlined/,
    'error when changing parent with undeferred constructor';
}

done_testing;
