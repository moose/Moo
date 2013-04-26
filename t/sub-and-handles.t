use strictures 1;
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

   package A;

   use Moo;
   extends 'ConsumesDelegateToBar';
   with 'Does::OverrideDelegate';

   has '+_barrer' => ( is => 'rw' );

   package B;

   use Moo;
   extends 'ConsumesDelegateToBar';

   sub _bar { 'extended' }

   has '+_barrer' => ( is => 'rw' );

   package D;

   use Moo;
   extends 'ConsumesDelegateToBar';

   sub _bar { 'extended' }

   has '+_barrer' => (
      is => 'rw',
      handles => { _baz => 'bar' },
   );
   package C;

   use Moo;
   extends 'ConsumesDelegateToBar';
   with 'Does::OverrideDelegate';

   has '+_barrer' => (
      is => 'rw',
      handles => { _baz => 'bar' },
   );
}

is(A->new->_bar, 'extended', 'overriding delegate method with role works');
is(D->new->_bar, 'extended', '... even when you specify other delegates in subclass');
is(D->new->_baz, 'unextended!', '... and said other delegate still works');
is(B->new->_bar, 'extended', 'overriding delegate method directly works');
is(C->new->_bar, 'extended', '... even when you specify other delegates in subclass');
is(C->new->_baz, 'unextended!', '... and said other delegate still works');

done_testing;

