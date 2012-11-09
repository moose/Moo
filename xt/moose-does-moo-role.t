use strictures 1;
use Test::More;
use Test::Exception;

use Moo::HandleMoose;

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

   package MooRoledMooseClass;
   use Moose;
   with 'MooRole';

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
      lives_and {
         my $o = $parent->new(
            e => $child->new(),
         );
         ok( $o->e->does("MooParentRole"), "$child does parent MooRole" );
         can_ok( $o->e, "role_method" );
         can_ok( $o->e, "parent_role_method" );
      };
   }
}

done_testing;
