use strict;
use warnings;

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

  our @ISA = qw(BaseClass);

  sub new {
    my $class = shift;
    $class->SUPER::new(@_);
  }
}

BEGIN {
  package ChildClass;
  use Moo;
  extends 'BaseClass'; our $EXTEND_FILE = __FILE__; our $EXTEND_LINE = __LINE__;

  unshift our @ISA, 'ExtraClass';
}

my $ex = exception {
  ChildClass->new;
};
like $ex, qr{Expected parent constructor of ChildClass to be BaseClass, but found ExtraClass},
  'Interfering with @ISA after using extends triggers error';
like $ex, qr{\Q(after $ChildClass::EXTEND_FILE line $ChildClass::EXTEND_LINE)\E},
  ' ... reporting location triggering constructor generation';

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
