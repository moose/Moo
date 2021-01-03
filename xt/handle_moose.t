use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Sub::Quote qw(quote_sub);

{
  package Foo;

  use Moo;

  has one => (is => 'ro');
  has two => (is => 'rw', init_arg => undef);
  has three => (is => 'ro', init_arg => 'THREE', required => 1);

  package Bar;

  use Moo::Role;

  has four => (is => 'ro');
  ::quote_sub 'Bar::quoted' => '1';

  package Baz;

  use Moo;

  extends 'Foo';

  with 'Bar';

  has five => (is => 'rw');
}

require Moose;

my $meta = Class::MOP::get_metaclass_by_name('Foo');

my $attr;

ok($attr = $meta->get_attribute('one'), 'Meta-attribute exists');
is($attr->get_read_method, 'one', 'Method name');
is($attr->get_read_method_ref->body, Foo->can('one'), 'Right method');

is(Foo->new(one => 1, THREE => 3)->one, 1, 'Accessor still works');

is(
  Foo->meta->get_attribute('one')->get_read_method, 'one',
  'Method name via ->meta'
);

$meta = Moose::Meta::Class->initialize('Spoon');

$meta->superclasses('Moose::Object');

Moose::Util::apply_all_roles($meta, 'Bar');

my $spoon = Spoon->new(four => 4);

is($spoon->four, 4, 'Role application ok');

{
   package MooRequiresFour;

   use Moo::Role;

   requires 'four';

   package MooRequiresGunDog;

   use Moo::Role;

   requires 'gun_dog';
}

is exception {
   Moose::Util::apply_all_roles($meta, 'MooRequiresFour');
}, undef, 'apply role with satisified requirement';

ok exception {
   Moose::Util::apply_all_roles($meta, 'MooRequiresGunDog');
}, 'apply role with unsatisified requirement';

{
  package WithNonMethods;
  use Scalar::Util qw(reftype);
  use Moo;

  my $meta = Class::MOP::get_metaclass_by_name(__PACKAGE__);
  ::ok(!$meta->has_method('reftype'),
    'imported sub before use Moo not included in inflated metaclass');
}

{
  package AnotherMooseRole;
  use Moose::Role;
  has attr1 => (is => 'ro');
}

ok(Moo::Role->is_role('AnotherMooseRole'),
  'Moose roles are Moo::Role->is_role');

{
  {
    package AMooClass;
    use Moo;
  }
  {
    package AMooRole;
    use Moo::Role;
  }
  my $c = Moo::Role->create_class_with_roles('AMooClass', 'AMooRole');
  my $meta = Class::MOP::get_metaclass_by_name($c);
  ok $meta, 'generated class via create_class_with_roles has metaclass';
}

done_testing;
