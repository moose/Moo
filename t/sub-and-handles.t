use strict;
use warnings;

use Test::More;

{
   package DelegateBar;

   use Moo;

   sub bar { 'unextended!' }

   package Does::DelegateToBar;

   use Moo::Role;

   has _barrer => (
      is => 'ro',
      default => sub { DelegateBar->new },
      handles => { _bar => 'bar' },
   );

   sub get_barrer { $_[0]->_barrer }

   package ConsumesDelegateToBar;

   use Moo;

   with 'Does::DelegateToBar';

   has bong => ( is => 'ro' );

   package Does::OverrideDelegate;

   use Moo::Role;

   sub _bar { 'extended' }

   package First;

   use Moo;
   extends 'ConsumesDelegateToBar';
   with 'Does::OverrideDelegate';

   has '+_barrer' => ( is => 'rw' );

   package Second;

   use Moo;
   extends 'ConsumesDelegateToBar';

   sub _bar { 'extended' }

   has '+_barrer' => ( is => 'rw' );

   package Fourth;

   use Moo;
   extends 'ConsumesDelegateToBar';

   sub _bar { 'extended' }

   has '+_barrer' => (
      is => 'rw',
      handles => { _baz => 'bar' },
   );
   package Third;

   use Moo;
   extends 'ConsumesDelegateToBar';
   with 'Does::OverrideDelegate';

   has '+_barrer' => (
      is => 'rw',
      handles => { _baz => 'bar' },
   );
}

is(First->new->_bar, 'extended', 'overriding delegate method with role works');
is(Fourth->new->_bar, 'extended', '... even when you specify other delegates in subclass');
is(Fourth->new->_baz, 'unextended!', '... and said other delegate still works');
is(Second->new->_bar, 'extended', 'overriding delegate method directly works');
is(Third->new->_bar, 'extended', '... even when you specify other delegates in subclass');
is(Third->new->_baz, 'unextended!', '... and said other delegate still works');

done_testing;
