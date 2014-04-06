use strictures 1;
use Test::Fatal;

BEGIN { require "t/moo-accessors.t"; }

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
  use Scalar::Util qw(looks_like_number);
  use Moo;

  my $meta = Class::MOP::get_metaclass_by_name(__PACKAGE__);
  ::ok(!$meta->has_method('looks_like_number'),
    'imported sub before use Moo not included in inflated metaclass');
}

{
  package AnotherMooseRole;
  use Moose::Role;
  has attr1 => (is => 'ro');
}

ok(Moo::Role->is_role('AnotherMooseRole'),
  'Moose roles are Moo::Role->is_role');

done_testing;
