use strict;
use warnings;

use Test::More;
use Test::Fatal;

$INC{'MyRole.pm'} = __FILE__;

{
  package MyClass;
  use Moo;
  ::like(::exception { with 'MyRole'; }, qr/MyRole is not a Moo::Role/,
    'error when composing non-role package');
}

done_testing;
