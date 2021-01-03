use strict;
use warnings;

use Test::More;
use Test::Fatal;

sub ArrayRef {
  my $type = sub {
    die unless ref $_[0] && ref $_[0] eq 'ARRAY';
  };
  $Moo::HandleMoose::TYPE_MAP{$type} = sub {
    require Moose::Util::TypeConstraints;
    Moose::Util::TypeConstraints::find_type_constraint("ArrayRef");
  };
  return ($type, @_);
}

{
  package ClassWithTypes;
  $INC{'ClassWithTypes.pm'} = __FILE__;
  use Moo;

  has split_comma => (is => 'ro', isa => ::ArrayRef, coerce => sub { [ split /,/, $_[0] ] } );
  has split_space => (is => 'ro', isa => ::ArrayRef, coerce => sub { [ split / /, $_[0] ] } );
  has bad_coerce => (is => 'ro', isa => ::ArrayRef, coerce => sub { $_[0] } );
}

my $o = ClassWithTypes->new(split_comma => 'a,b c,d', split_space => 'a,b c,d');
is_deeply $o->split_comma, ['a','b c','d'], 'coerce with prebuilt type works';
is_deeply $o->split_space, ['a,b','c,d'], ' ... and with different coercion on same type';

{
  package MooseSubclassWithTypes;
  use Moose;
  extends 'ClassWithTypes';
}

my $o2 = MooseSubclassWithTypes->new(split_comma => 'a,b c,d', split_space => 'a,b c,d');
is_deeply $o2->split_comma, ['a','b c','d'], 'moose subclass has correct coercion';
is_deeply $o2->split_space, ['a,b','c,d'], ' ... and with different coercion on same type';

like
  exception { MooseSubclassWithTypes->new(bad_coerce => 1) },
  qr/Validation failed for 'ArrayRef' with value/,
  'inflated type has correct name';

done_testing;
