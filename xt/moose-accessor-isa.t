use strictures 1;
use Test::More;
use Test::Exception;

use Moo::HandleMoose;

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
}

lives_ok {
   Bar->new(frooh => 1, frew => 1);
} 'creation of valid Bar';

dies_ok {
   Bar->new(frooh => 'silly', frew => 1);
} 'creation of invalid Bar validated by coderef';

dies_ok {
   Bar->new(frooh => 1, frew => 'goose');
} 'creation of invalid Bar validated by quoted sub';

done_testing;
