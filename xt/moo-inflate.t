use strictures 1;
use Test::More;
use Test::Fatal;

{
   package MooClass;
   use Moo;
}
use Moose ();
use Moo::Role ();

ok !$Moo::HandleMoose::DID_INJECT{'MooClass'},
  "No metaclass generated for Moo class on initial Moose load";
Moo::Role->is_role('MooClass');
ok !$Moo::HandleMoose::DID_INJECT{'MooClass'},
  "No metaclass generated for Moo class after testing with ->is_role";

done_testing;
