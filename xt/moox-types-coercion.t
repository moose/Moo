use strictures 1;
use Test::More;

{
  package ClassWithTypes;
  $INC{'ClassWithTypes.pm'} = __FILE__;
  use Moo;
  use MooX::Types::MooseLike::Base qw(ArrayRef);

  has split_comma => (is => 'ro', isa => ArrayRef, coerce => sub { [ split /,/, $_[0] ] } );
  has split_space => (is => 'ro', isa => ArrayRef, coerce => sub { [ split / /, $_[0] ] } );
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

done_testing;
