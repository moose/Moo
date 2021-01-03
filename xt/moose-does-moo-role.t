use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
   package MooParentRole;
   use Moo::Role;
   sub parent_role_method { 1 };

   package MooRole;
   use Moo::Role;
   with 'MooParentRole';
   sub role_method { 1 };

   package MooRoledMooClass;
   use Moo;
   with 'MooRole';

   has 'some_attr' => (is => 'ro');

   package MooRoledMooseClass;
   use Moose;
   with 'MooRole';

   has 'some_attr' => (is => 'ro');

   package MooseParent;
   use Moose;

   has e => (
      is       => 'ro',
      required => 1,
      does     => 'MooRole',
   );

   package MooParent;
   use Moo;

   has e => (
      is       => 'ro',
      required => 1,
      does     => 'MooRole',
   );
}

for my $parent (qw(MooseParent MooParent)) {
   for my $child (qw(MooRoledMooClass MooRoledMooseClass)) {
      is(exception {
         my $o = $parent->new(
            e => $child->new(),
         );
         ok( $o->e->does("MooParentRole"), "$child does parent MooRole" );
         can_ok( $o->e, "role_method" );
         can_ok( $o->e, "parent_role_method" );
         ok($o->e->meta->has_method('role_method'), 'Moose knows about role_method');
         ok($o->e->meta->has_method('parent_role_method'), 'Moose knows about parent_role_method');
      }, undef);
   }
}

{
  package MooClass2;
  use Moo;
}

{
  ok !MooClass2->does('MooRole'),
    'Moo class does not do unrelated role';
  my $meta = Class::MOP::get_metaclass_by_name('MooClass2');
  is ref $meta, 'Moo::HandleMoose::FakeMetaClass',
    'does call for Moo only classes did not inflate';
}

done_testing;
