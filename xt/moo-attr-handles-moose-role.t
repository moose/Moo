use strict;
use warnings;

use Test::More;

{
   package MooseRole;
   use Moose::Role;

   sub warble { "warble" }
   $INC{"MooseRole.pm"} = __FILE__;
}

{
   package MooseClass;
   use Moose;
   with 'MooseRole';
}

{
  package MooClass;
  use Moo;

  has attr => (
      is => 'ro',
      handles => 'MooseRole',
  );
}

my $o = MooClass->new(attr => MooseClass->new);
isa_ok( $o, 'MooClass' );
can_ok( $o, 'warble' );
is( $o->warble, "warble", 'Delegated method called correctly' );

done_testing;
