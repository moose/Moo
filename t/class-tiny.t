use strictures 1;
use Test::More;

{
  package MyClass0;

  BEGIN { our @ISA = 'ZeroZero' }

  use Class::Tiny;
}

BEGIN {
  is(
    $INC{'Class/Tiny/Object.pm'}, undef,
    'Object.pm not loaded if not required'
  );
}

{
  package MyClass1;

  use Class::Tiny;
}

is_deeply(
  [ @MyClass1::ISA ], [ 'Class::Tiny::Object' ], 'superclass defaulted'
);

{
  package MyClass2;

  use base qw(MyClass1);
  use Class::Tiny;
}

is_deeply(
  [ @MyClass2::ISA ], [ 'MyClass1' ], 'prior superclass left alone'
);

{
  package MyClass3;

  use Class::Tiny;

  extends 'MyClass2';
}

is_deeply(
  [ @MyClass3::ISA ], [ 'MyClass2' ], 'extends sets superclass'
);

{
  package MyClass4;

  use Class::Tiny;

  extends 'WhatTheFlyingFornication';

  extends qw(MyClass2 MyClass3);
}

is_deeply(
  [ @MyClass4::ISA ], [ qw(MyClass2 MyClass3) ], 'extends overwrites'
);

{
  package MyClass5;

  use Class::Tiny;

  sub foo { 'foo' }

  around foo => sub { my $orig = shift; $orig->(@_).' with around' };
}

is(MyClass5->foo, 'foo with around', 'method modifier');

done_testing;
