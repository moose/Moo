use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
   package FrewWithIsa;
   use Moo::Role;
   use Sub::Quote;

   has frooh => (
      is => 'rw',
      isa => sub { die 'not int' unless $_[0] =~ /^\d$/ },
   );

   has frew => (
      is => 'rw',
      isa => quote_sub(q{ die 'not int' unless $_[0] =~ /^\d$/ }),
   );

   package Bar;
   use Moose;
   with 'FrewWithIsa';

   package OffByOne;
   use Moo::Role;

   has off_by_one => (is => 'rw', coerce => sub { $_[0] + 1 });

   package Baz;
   use Moo;

   with 'OffByOne';

   package Quux;
   use Moose;

   with 'OffByOne';

   __PACKAGE__->meta->make_immutable;
}

is(exception {
   Bar->new(frooh => 1, frew => 1);
}, undef, 'creation of valid Bar');

ok exception {
   Bar->new(frooh => 'silly', frew => 1);
}, 'creation of invalid Bar validated by coderef';

ok exception {
   Bar->new(frooh => 1, frew => 'goose');
}, 'creation of invalid Bar validated by quoted sub';

sub test_off_by_one {
  my ($class, $type) = @_;

  my $obo = $class->new(off_by_one => 1);

  is($obo->off_by_one, 2, "Off by one (new) ($type)");

  $obo->off_by_one(41);

  is($obo->off_by_one, 42, "Off by one (set) ($type)");
}

test_off_by_one('Baz', 'Moo');
test_off_by_one('Quux', 'Moose');

my $coerce_constraint = Quux->meta->get_attribute('off_by_one')
  ->type_constraint->constraint;
like exception { $coerce_constraint->() }, qr/This is not going to work/,
  'generated constraint is not a null constraint';

done_testing;
