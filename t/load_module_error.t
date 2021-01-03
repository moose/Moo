use strict;
use warnings;

use Test::More;
use Test::Fatal;
use lib 't/lib';
use InlineModule (
  'BrokenExtends' => qq{
    package BrokenExtends;
    use Moo;
    extends "This::Class::Does::Not::Exist::${\int rand 50000}";
  },
  'BrokenExtends::Child' => q{
    package BrokenExtends::Child;
    use Moo;

    extends 'BrokenExtends';
  },
);

my $e = exception { require BrokenExtends::Child };
ok $e, "got a crash";
unlike $e, qr/Unknown error/, "it came with a useful error message";

done_testing;
