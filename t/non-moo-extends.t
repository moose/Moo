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
is $o->built, 1, 'BUILD called correct number of times';

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

{
  package ClassG;
  use Sub::Defer;
  defer_sub __PACKAGE__.'::new' => sub { sub { bless {}, $_[0] } };
}

{
  package ClassH;
  use Moo;
  extends 'ClassG';
}

{
  my $o = eval { ClassH->new };
  ok $o,
    'inheriting from non-Moo with deferred new works'
    or diag $@;
  isa_ok $o, 'ClassH';
}

{
  package ClassI;
  sub new {
    my $self = shift;
    my $class = ref $self ? ref $self : $self;
    bless {
      (ref $self ? %$self : ()),
      @_,
    }, $class;
  }
}

{
  package ClassJ;
  use Moo;
  extends 'ClassI';
  has 'attr' => (is => 'ro');
}

{
  my $o1 = ClassJ->new(attr => 1);
  my $o2 = $o1->new;
  is $o2->attr, 1,
    'original invoker passed to parent new';
}

done_testing;
