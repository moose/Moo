use strict;
use warnings;
use Test::More;

{
    package ClassA;
    use Moo;

    has 'foo' => ( is => 'ro');
    has built => (is => 'rw', default => 0);

    sub BUILD {
      $_[0]->built($_[0]->built+1);
    }
}

{
    package ClassB;
    our @ISA = 'ClassA';
    sub blorp {};
    sub new {
      $_[0]->SUPER::new(@_[1..$#_]);
    }
}

{
  package ClassC;
  use Moo;
  extends 'ClassB';
  has bar => (is => 'ro');
}

{
  package ClassD;
  our @ISA = 'ClassC';
}

my $o = ClassD->new(foo => 1, bar => 2);
isa_ok $o, 'ClassD';
is $o->foo, 1, 'superclass attribute has correct value';
is $o->bar, 2, 'subclass attribute has correct value';
{
  local $TODO = "BUILD called extra for mixed Moo/non-Moo classes";
  is $o->built, 1, 'BUILD called correct number of times';
}

{
  package ClassE;
  sub new {
    return ClassF->new;
  }
}

{
  package ClassF;
  use Moo;
  extends 'Moo::Object', 'ClassE';
}

{
  my $o = eval { ClassF->new };
  ok $o,
    'explicit inheritence from Moo::Object works around broken constructor'
    or diag $@;
  isa_ok $o, 'ClassF';
}

done_testing;
