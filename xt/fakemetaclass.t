use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moo::HandleMoose::FakeMetaClass;

sub Foo::bar { 'bar' }

my $fake = bless { name => 'Foo' }, 'Moo::HandleMoose::FakeMetaClass';

my $bar = $fake->get_method('bar');
is $bar->body, \&Foo::bar,
  'able to call moose meta methods';

my $fm = 'Moo::HandleMoose::FakeMetaClass';

is exception {
  my $can = $fm->can('can');
  is $can, \&Moo::HandleMoose::FakeMetaClass::can,
    'can usable as class method';

  ok $fm->isa($fm),
    'isa usable as class method';

  local $Moo::HandleMoose::FakeMetaClass::VERSION = 5;
  is $fm->VERSION, 5,
    'VERSION usable as class method';
}, undef,
  'no errors calling isa, can, or VERSION';

like exception {
  $fm->missing_method;
}, qr/Can't call missing_method without object instance/,
  'nonexistent methods give correct error when called on class';

done_testing;
