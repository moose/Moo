use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
  package Foo;
  use Moo;
  has one => (is => 'ro');
}

no Moo::sification;
is exception { Foo->meta->make_immutable }, undef,
  'make_immutable allowed under no Moo::sification';

like exception { Foo->meta->get_methods_list },
  qr/^Can't inflate Moose metaclass with Moo::sification disabled/,
  'meta methods blocked under no Moo::sification';

is exception {
  is +Foo->meta->can('can'), \&Moo::HandleMoose::FakeMetaClass::can,
    '->meta->can falls back to default under no Moo::sification';
}, undef,
  '->meta->can works under no Moo::sification';

is exception {
  ok +Foo->meta->isa('Moo::HandleMoose::FakeMetaClass'),
    '->meta->isa falls back to default under no Moo::sification';
}, undef,
  '->meta->isa works under no Moo::sification';

like exception { Foo->meta->get_methods_list },
  qr/^Can't inflate Moose metaclass with Moo::sification disabled/,
  'meta methods blocked under no Moo::sification';

require Moo::HandleMoose;
like exception { Moo::HandleMoose->import },
  qr/^Can't inflate Moose metaclass with Moo::sification disabled/,
  'Moo::HandleMoose->import blocked under no Moo::sification';

done_testing;
