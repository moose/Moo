use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
  package MyClass0;

  BEGIN { our @ISA = 'ZeroZero' }

  use Moo;
}

BEGIN {
  is(
    $INC{'Moo/Object.pm'}, undef,
    'Object.pm not loaded if not required'
  );
}

{
  package MyClass1;

  use Moo;
}

is_deeply(
  [ @MyClass1::ISA ], [ 'Moo::Object' ], 'superclass defaulted'
);

{
  package MyClass2;

  use base qw(MyClass1);
  use Moo;
}

is_deeply(
  [ @MyClass2::ISA ], [ 'MyClass1' ], 'prior superclass left alone'
);

{
  package MyClass3;

  use Moo;

  extends 'MyClass2';
}

is_deeply(
  [ @MyClass3::ISA ], [ 'MyClass2' ], 'extends sets superclass'
);

{ package WhatTheFlyingFornication; sub wtff {} }

{
  package MyClass4;

  use Moo;

  extends 'WhatTheFlyingFornication';

  extends qw(MyClass2 MyClass3);
}

is_deeply(
  [ @MyClass4::ISA ], [ qw(MyClass2 MyClass3) ], 'extends overwrites'
);

{
  package MyClass5;

  use Moo;

  sub foo { 'foo' }

  around foo => sub { my $orig = shift; $orig->(@_).' with around' };

  ::like ::exception {
    around bar => sub { 'bar' };
  }, qr/not found/,
    'error thrown when modifiying missing method';
}

is(MyClass5->foo, 'foo with around', 'method modifier');

{
  package MyClass6;
  use Moo;
  sub new {
    bless {}, $_[0];
  }
}

{
  package MyClass7;
  use Moo;

  ::is ::exception {
    extends 'MyClass6';
    has foo => (is => 'ro');
    __PACKAGE__->new;
  }, undef,
    'can extend Moo class with overridden new';
}

done_testing;
