use strict;
use warnings;

use Test::More;

{
   package LazyFrew;

   our $default_ran = 0;
   our $quoted_default_ran = 0;
   our $builder_ran = 0;

   use Moo::Role;
   use Sub::Quote;

   has frooh => (
      is => 'rw',
      default => sub {
         $default_ran = 1;
         'test frooh'
      },
      lazy => 1,
   );

   has frew => (
      is => 'rw',
      default => quote_sub(q{
         $$quoted_default_ran = 1;
         'test frew'
      }, { '$quoted_default_ran' => \\$quoted_default_ran }),
      lazy => 1,
   );

   has frioux => (
      is => 'rw',
      builder => 'build_frioux',
      lazy => 1,
   );

   sub build_frioux {
      $builder_ran = 1;
      'test frioux'
   }

   package Bar;
   use Moose;
   with 'LazyFrew';
}

my $x = Bar->new;
ok(!$LazyFrew::default_ran, 'default has not run yet');
ok(!$LazyFrew::quoted_default_ran, 'quoted default has not run yet');
ok(!$LazyFrew::builder_ran, 'builder has not run yet');

is($x->frooh, 'test frooh', 'frooh defaulted correctly');

ok($LazyFrew::default_ran, 'default ran');
ok(!$LazyFrew::quoted_default_ran, 'quoted default has not run yet');
ok(!$LazyFrew::builder_ran, 'builder has not run yet');

is($x->frew, 'test frew', 'frew defaulted correctly');

ok($LazyFrew::default_ran, 'default ran');
ok($LazyFrew::quoted_default_ran, 'quoted default ran');
ok(!$LazyFrew::builder_ran, 'builder has not run yet');

is($x->frioux, 'test frioux', 'frioux built correctly');

ok($LazyFrew::default_ran, 'default ran');
ok($LazyFrew::quoted_default_ran, 'quoted default ran');
ok($LazyFrew::builder_ran, 'builder ran');

done_testing;
