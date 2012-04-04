use strictures 1;
use Test::More;
use Test::Exception;

use Moo::HandleMoose;

{
   package MooRole;
   use Moo::Role;

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
      lives_ok {
         $parent->new(
            e => $child->new(),
         );
      } "$parent instantiated with a $child delegate that does a MooRole";
   }
}

done_testing;
