use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
  package One; use Moo::Role;
  around foo => sub { my $orig = shift; (__PACKAGE__, $orig->(@_)) };
  package Two; use Moo::Role;
  around foo => sub { my $orig = shift; (__PACKAGE__, $orig->(@_)) };
  package Three; use Moo::Role;
  around foo => sub { my $orig = shift; (__PACKAGE__, $orig->(@_)) };
  package Four; use Moo::Role;
  around foo => sub { my $orig = shift; (__PACKAGE__, $orig->(@_)) };
  package BaseClass; sub foo { __PACKAGE__ }
}

foreach my $combo (
  [ qw(One Two Three Four) ],
  [ qw(Two Four Three) ],
  [ qw(One Two) ]
) {
  my $combined = Moo::Role->create_class_with_roles('BaseClass', @$combo);
  is_deeply(
    [ $combined->foo ], [ reverse(@$combo), 'BaseClass' ],
    "${combined} ok"
  );
  my $object = bless({}, 'BaseClass');
  Moo::Role->apply_roles_to_object($object, @$combo);
  is(ref($object), $combined, 'Object reblessed into correct class');
}

{
  package RoleWithAttr;
  use Moo::Role;

  has attr1 => (is => 'ro', default => -1);

  package RoleWithAttr2;
  use Moo::Role;

  has attr2 => (is => 'ro', default => -2);

  package ClassWithAttr;
  use Moo;

  has attr3 => (is => 'ro', default => -3);
}

Moo::Role->apply_roles_to_package('ClassWithAttr', 'RoleWithAttr', 'RoleWithAttr2');
my $o = ClassWithAttr->new(attr1 => 1, attr2 => 2, attr3 => 3);
is($o->attr1, 1, 'attribute from role works');
is($o->attr2, 2, 'attribute from role 2 works');
is($o->attr3, 3, 'attribute from base class works');

{
  package SubClassWithoutAttr;
  use Moo;
  extends 'ClassWithAttr';
}

my $o2 = Moo::Role->create_class_with_roles(
  'SubClassWithoutAttr', 'RoleWithAttr')->new;
is($o2->attr3, -3, 'constructor includes base class');
is($o2->attr2, -2, 'constructor includes role');

{
  package AccessorExtension;
  use Moo::Role;
  around 'generate_method' => sub {
    my $orig = shift;
    my $me = shift;
    my ($into, $name) = @_;
    $me->$orig(@_);
    no strict 'refs';
    *{"${into}::_${name}_marker"} = sub { };
  };
}

{
  package RoleWithReq;
  use Moo::Role;
  requires '_attr1_marker';
}

is exception {
  package ClassWithExtension;
  use Moo;
  Moo::Role->apply_roles_to_object(
    Moo->_accessor_maker_for(__PACKAGE__),
    'AccessorExtension');

  with qw(RoleWithAttr RoleWithReq);
}, undef, 'apply_roles_to_object correctly calls accessor generator';

{
  package EmptyClass;
  use Moo;
}

{
  package RoleWithReq2;
  use Moo::Role;
  requires 'attr2';
}

is exception {
  Moo::Role->create_class_with_roles(
    'EmptyClass', 'RoleWithReq2', 'RoleWithAttr2');
}, undef, 'create_class_with_roles accepts attributes for requirements';

like exception {
  Moo::Role->create_class_with_roles(
    'EmptyClass', 'RoleWithReq2', 'RoleWithAttr');
}, qr/Can't apply .* missing attr2/,
  'create_class_with_roles accepts attributes for requirements';

{
  package RoleWith2Attrs;
  use Moo::Role;

  has attr1 => (is => 'ro', default => -1);
  has attr2 => (is => 'ro', default => -2);
}

foreach my $combo (
  [qw(RoleWithAttr RoleWithAttr2)],
  [qw(RoleWith2Attrs)],
) {
  is exception {
    my $o = Moo::Role->apply_roles_to_object(
      EmptyClass->new, @$combo);
    is($o->attr1, -1, 'first attribute works');
    is($o->attr2, -2, 'second attribute works');
  }, undef, "apply_roles_to_object with multiple attrs with defaults (@$combo)";
}

{
  package Some::Class;
  use Moo;
  sub foo { 1 }
}

like exception {
  Moo::Role->apply_roles_to_package('EmptyClass', 'Some::Class');
}, qr/Some::Class is not a Moo::Role/,
  'apply_roles_to_package throws error on non-role';

like exception {
  Moo::Role->apply_single_role_to_package('EmptyClass', 'Some::Class');
}, qr/Some::Class is not a Moo::Role/,
  'apply_single_role_to_package throws error on non-role';

like exception {
  Moo::Role->create_class_with_roles('EmptyClass', 'Some::Class');
}, qr/Some::Class is not a Moo::Role/,
  'can only create class with roles';

delete Moo->_constructor_maker_for('Some::Class')->{attribute_specs};
is exception {
  Moo::Role->apply_roles_to_package('Some::Class', 'RoleWithAttr');
}, undef,
  'apply_roles_to_package copes with missing attribute specs';

{
  package Non::Moo::Class;
  sub new { bless {}, $_[0] }
}

Moo::Role->apply_roles_to_package('Non::Moo::Class', 'RoleWithAttr');
ok +Non::Moo::Class->can('attr1'),
  'can apply role with attributes to non Moo class';

done_testing;
