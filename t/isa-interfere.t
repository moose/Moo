use Moo::_strictures;
use Test::More;
use Test::Fatal;

use Moo ();

BEGIN {
  package BaseClass;

  sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
  }
}

BEGIN {
  package ExtraClass;

  sub new {
    my $class = shift;
    $class->next::method(@_);
  }
}

BEGIN {
  package ChildClass;
  use Moo;
  extends 'BaseClass';

  unshift our @ISA, 'ExtraClass';
}

like exception {
  ChildClass->new;
}, qr/Expected parent constructor of ChildClass to be BaseClass, but found ExtraClass/,
  'Interfering with @ISA after using extends triggers error';

BEGIN {
  package ExtraClass2;

  sub foo { 'garp' }
}

BEGIN {
  package ChildClass2;
  use Moo;
  extends 'BaseClass';

  unshift our @ISA, 'ExtraClass2';
}

is exception {
  ChildClass2->new;
}, undef,
  'Changing @ISA without effecting constructor does not trigger error';

done_testing;
