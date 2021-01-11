use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moo::_Utils qw(_linear_isa);

BEGIN {
  package Method::Generate::Accessor::Role::ArrayRefInstance;

  use Moo::Role;

  sub _generate_simple_get {
    my ($self, $me, $name, $spec) = @_;
    "${me}->[${\$spec->{index}}]";
  }

  sub _generate_core_set {
    my ($self, $me, $name, $spec, $value) = @_;
    "${me}->[${\$spec->{index}}] = $value";
  }

  sub _generate_simple_has {
    my ($self, $me, $name, $spec) = @_;
    "defined ${me}->[${\$spec->{index}}]";
  }

  sub _generate_simple_clear {
    my ($self, $me, $name, $spec) = @_;
    "undef(${me}->[${\$spec->{index}}])";
  }

  sub generate_multi_set {
    my ($self, $me, $to_set, $from, $specs) = @_;
    "\@{${me}}[${\join ', ', map $specs->{$_}{index}, @$to_set}] = $from";
  }

  sub _generate_xs {
    my ($self, $type, $into, $name, $slot, $spec) = @_;
    require Class::XSAccessor::Array;
    Class::XSAccessor::Array->import(
      class => $into,
      $type => { $name => $spec->{index} }
    );
    $into->can($name);
  }

  sub default_construction_string { '[]' }

  sub MooX::ArrayRef::import {
    Moo::Role->apply_roles_to_object(
      Moo->_accessor_maker_for(scalar caller),
      'Method::Generate::Accessor::Role::ArrayRefInstance'
    );
  }
  $INC{"MooX/ArrayRef.pm"} = 1;
}

{
  package ArrayTest1;

  use Moo;
  use MooX::ArrayRef;

  has one => (is => 'ro');
  has two => (is => 'ro');
  has three => (is => 'ro');
}

my $o = ArrayTest1->new(one => 1, two => 2, three => 3);

is_deeply([ @$o ], [ 1, 2, 3 ], 'Basic object ok');

{
  package ArrayTest2;

  use Moo;

  extends 'ArrayTest1';

  has four => (is => 'ro');
}

$o = ArrayTest2->new(one => 1, two => 2, three => 3, four => 4);

is_deeply([ @$o ], [ 1, 2, 3, 4 ], 'Subclass object ok');

{
  package ArrayTestRole;

  use Moo::Role;

  has four => (is => 'ro');

  package ArrayTest3;

  use Moo;

  extends 'ArrayTest1';

  with 'ArrayTestRole';
}

$o = ArrayTest3->new(one => 1, two => 2, three => 3, four => 4);

is_deeply([ @$o ], [ 1, 2, 3, 4 ], 'Subclass object w/role');

my $c = Moo::Role->create_class_with_roles('ArrayTest1', 'ArrayTestRole');

$o = $c->new(one => 1, two => 2, three => 3, four => 4);

is_deeply([ @$o ], [ 1, 2, 3, 4 ], 'Generated subclass object w/role');

is exception {
  Moo::Role->create_class_with_roles('ArrayTest1', 'ArrayTestRole');
}, undef,
  'creating class with role again';

{
  package ArrayNonMoo;
  sub new { bless [], $_[0] }
}

{
  package ArrayTest4;

  use Moo;
  use MooX::ArrayRef;

  extends 'ArrayNonMoo';

  has one => (is => 'ro');
  has two => (is => 'ro');
  has three => (is => 'ro');
  has four => (is => 'ro');
}

$o = ArrayTest4->new(one => 1, two => 2, three => 3, four => 4);

is_deeply([ @$o ], [ 1, 2, 3, 4 ], 'Subclass of non-Moo object');


{
  package ArrayTestRole2;
  use Moo::Role;

  has four => (is => 'ro');
}

{
  my ($new_c) = Moo::Role->_composite_name('ArrayTest1', 'ArrayTestRole2');
  {
    no strict 'refs';
    # cause ISA to exist somehow
    @{"${new_c}::ISA"} = ();
  }
  my $c = Moo::Role->create_class_with_roles('ArrayTest1', 'ArrayTestRole2');
  is_deeply +_linear_isa($c), [$c, 'ArrayTest1', 'Moo::Object'],
    'mro::get_linear_isa is correct if create_class_with_roles target class @ISA existed';
}

done_testing;
