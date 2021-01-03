use strict;
use warnings;

use Test::More;

{
   package ModifyFoo;
   use Moo::Role;

   our $before_ran = 0;
   our $around_ran = 0;
   our $after_ran = 0;

   before foo => sub { $before_ran = 1 };
   after foo => sub { $after_ran = 1 };
   around foo => sub {
      my ($orig, $self, @rest) = @_;
      $self->$orig(@rest);
      $around_ran = 1;
   };

   package Bar;
   use Moose;
   with 'ModifyFoo';

   sub foo { }
}

my $bar = Bar->new;

ok(!$ModifyFoo::before_ran, 'before has not run yet');
ok(!$ModifyFoo::after_ran, 'after has not run yet');
ok(!$ModifyFoo::around_ran, 'around has not run yet');
$bar->foo;
ok($ModifyFoo::before_ran, 'before ran');
ok($ModifyFoo::after_ran, 'after ran');
ok($ModifyFoo::around_ran, 'around ran');

{
  package ModifyMultiple;
  use Moo::Role;
  our $before = 0;

  before 'foo', 'bar' => sub {
    $before++;
  };

  package Baz;
  use Moose;
  with 'ModifyMultiple';

  sub foo {}
  sub bar {}
}

my $baz = Baz->new;
my $pre = $ModifyMultiple::before;
$baz->foo;
is $ModifyMultiple::before, $pre+1, "before applies to first of multiple subs";
$baz->bar;
is $ModifyMultiple::before, $pre+2, "before applies to second of multiple subs";

done_testing;
