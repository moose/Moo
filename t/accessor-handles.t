use strict;
use warnings;

use Test::More;
use Test::Fatal;
use lib 't/lib';

{
  package Baz;
  use Moo;
  sub beep {'beep'}

  sub is_passed_undefined { !defined($_[0]) ? 'bar' : 'fail' }
}

{
  package Robot;

  use Moo::Role;

  requires 'smash';
  $INC{"Robot.pm"} = 1;

}

{
  package Foo;

  use Moo;

  with 'Robot';

  sub one {1}
  sub two {2}
  sub smash {'smash'}
  sub yum {$_[1]}
}

use InlineModule (
  ExtRobot => q{
    package ExtRobot;

    use Moo::Role;

    requires 'beep';

    1;
  },
);

{
  package Bar;

  use Moo;

  has foo => ( is => 'ro', handles => [ qw(one two) ] );
  has foo2 => ( is => 'ro', handles => { un => 'one' } );
  has foo3 => ( is => 'ro', handles => 'Robot' );
  has foo4 => ( is => 'ro', handles => {
     eat_curry => [ yum => 'Curry!' ],
  });
  has foo5 => ( is => 'ro', handles => 'ExtRobot' );
  has foo6 => ( is => 'rw',
                handles => { foobot => '${\\Baz->can("beep")}'},
                default => sub { 0 } );
  has foo7 => ( is => 'rw',
                handles => { foobar => '${\\Baz->can("is_passed_undefined")}'},
                default => sub { undef } );

  has foo8 => (
    is => 'rw',
    handles => [ 'foo8_gone' ],
  );
}

my $bar = Bar->new(
  foo => Foo->new, foo2 => Foo->new, foo3 => Foo->new, foo4 => Foo->new,
  foo5 => Baz->new
);

is $bar->one, 1, 'handles works';
is $bar->two, 2, 'handles works for more than one method';

is $bar->un, 1, 'handles works for aliasing a method';

is $bar->smash, 'smash', 'handles works for a role';

is $bar->beep, 'beep', 'handles loads roles';

is $bar->eat_curry, 'Curry!', 'handles works for currying';

is $bar->foobot, 'beep', 'asserter checks for existence not truth, on false value';

is $bar->foobar, 'bar', 'asserter checks for existence not truth, on undef ';

like exception {
  $bar->foo8_gone;
}, qr/^Attempted to access 'foo8' but it is not set/,
  'asserter fails with correct message';

ok(my $e = exception {
  package Baz;
  use Moo;
  has foo => ( is => 'ro', handles => 'Robot' );
  sub smash { 1 };
}, 'handles will not overwrite locally defined method');
like $e, qr{You cannot overwrite a locally defined method \(smash\) with a delegation},
  '... and has correct error message';

is exception {
  package Buzz;
  use Moo;
  has foo => ( is => 'ro', handles => 'Robot' );
  sub smash;
}, undef, 'handles can overwrite predeclared subs';

ok(exception {
  package Fuzz;
  use Moo;
  has foo => ( is => 'ro', handles => $bar );
}, 'invalid handles (object) throws exception');

like exception {
  package Borf;
  use Moo;
  has foo => ( is => 'ro', handles => 'Bar' );
}, qr/is not a Moo::Role/,
  'invalid handles (class) throws exception';

done_testing;
