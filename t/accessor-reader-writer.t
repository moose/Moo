use strictures 1;
use Test::More;
use Test::Fatal;

my @result;

{
  package Foo;

  use Moo;

  has one => (
    is     => 'rw',
    reader => 'get_one',
    writer => 'set_one',
  );

  sub one {'sub'}

  has two => (
    is     => 'lazy',
    default => sub { 2 },
    reader => 'get_two',
  );

  has three => (
    is     => 'rwp',
    reader => 'get_three',
    writer => 'set_three',
  );
}

{
  package Bar;

  use Moo;

  has two => (
    is     => 'rw',
    accessor => 'TWO',
  );
}

my $foo = Foo->new(one => 'lol');
my $bar = Bar->new(two => '...');

is( $foo->get_one, 'lol', 'reader works' );
$foo->set_one('rofl');
is( $foo->get_one, 'rofl', 'writer works' );
is( $foo->one, 'sub', 'reader+writer = no accessor' );

is( $foo->get_two, 2, 'lazy doesn\'t override reader' );

is( $foo->can('two'), undef, 'reader+ro = no accessor' );

ok( $foo->can('get_three'), 'rwp doesn\'t override reader');
ok( $foo->can('set_three'), 'rwp doesn\'t override writer');

ok( exception { $foo->get_one('blah') }, 'reader dies on write' );

is( $bar->TWO, '...', 'accessor works for reading' );
$bar->TWO('!!!');
is( $bar->TWO, '!!!', 'accessor works for writing' );

{
  package Baz;
  use Moo;

  ::is(::exception {
    has '@three' => (
      is     => 'lazy',
      default => sub { 3 },
      reader => 'three',
    );
  }, undef, 'declaring non-identifier attribute with proper reader works');
}

is( Baz->new->three, 3, '... and reader works');

done_testing;
