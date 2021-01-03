use strict;
use warnings;

use Test::More;

eval q{
  package TinyRole;
  $INC{'TinyRole.pm'} = __FILE__;
  use Role::Tiny;

  sub role_tiny_method { 219 }
  1;
} or die $@;

require Moo::Role;
require Moose;

eval q{
  package TinyRoleAfterMoo;
  $INC{'TinyRoleAfterMoo.pm'} = __FILE__;
  use Role::Tiny;

  sub role_tiny_after_method { 42 }
  1;
} or die $@;

eval q{
  package Some::Moose::Class;
  use Moose;
  1;
} or die $@;

eval q{
  package Some::Moose::Class;
  with 'TinyRole';
};
$@ =~ s/\n.*//s;
is $@, '', 'Moose can consume Role::Tiny created before Moo loaded';

eval q{
  package Some::Moose::Class;
  with 'TinyRoleAfterMoo';
};
$@ =~ s/\n.*//s;
is $@, '', 'Moose can consume Role::Tiny created after Moo loaded';

done_testing;
