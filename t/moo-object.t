use strictures 1;
use Test::More;
use Test::Fatal;

no warnings 'once';

{
  package MyClass;
  use base 'Moo::Object';
}

is_deeply +MyClass->BUILDARGS({foo => 'bar'}), {foo => 'bar'},
  'BUILDARGS: hashref accepted';
is_deeply +MyClass->BUILDARGS(foo => 'bar'), {foo => 'bar'},
  'BUILDARGS: hash accepted';
like
  exception { MyClass->BUILDARGS('foo') },
  qr/Single parameters to new\(\) must be a HASH ref/,
  'BUILDARGS: non-hashref single element rejected';
like
  exception { MyClass->BUILDARGS(foo => 'bar', 5) },
  qr/You passed an odd number of arguments/,
  'BUILDARGS: odd number of elements rejected';

MyClass->new;
my $built = 0;
*MyClass::BUILD = *MyClass::BUILD = sub { $built++ };
MyClass->new;
is $built, 0, 'BUILD only checked for once';

{
  my $meta = MyClass->meta;
  $meta->make_immutable;
  is $INC{'Moo/HandleMoose.pm'}, undef,
    "->meta->make_immutable doesn't load HandleMoose";
  $meta->DESTROY;
}
is $INC{'Moo/HandleMoose.pm'}, undef,
  "destroying fake metaclass doesn't load HandleMoose";

done_testing;
