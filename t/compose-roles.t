use strictures 1;
use Test::More;
use Test::Fatal;

{
  package One; use Role::Tiny;
  around foo => sub { my $orig = shift; (__PACKAGE__, $orig->(@_)) };
  package Two; use Role::Tiny;
  around foo => sub { my $orig = shift; (__PACKAGE__, $orig->(@_)) };
  package Three; use Role::Tiny;
  around foo => sub { my $orig = shift; (__PACKAGE__, $orig->(@_)) };
  package Four; use Role::Tiny;
  around foo => sub { my $orig = shift; (__PACKAGE__, $orig->(@_)) };
  package Base; sub foo { __PACKAGE__ }
}

foreach my $combo (
  [ qw(One Two Three Four) ],
  [ qw(Two Four Three) ],
  [ qw(One Two) ]
) {
  my $combined = Role::Tiny->create_class_with_roles('Base', @$combo);
  is_deeply(
    [ $combined->foo ], [ reverse(@$combo), 'Base' ],
    "${combined} ok"
  );
  my $object = bless({}, 'Base');
  Role::Tiny->apply_roles_to_object($object, @$combo);
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


done_testing;
