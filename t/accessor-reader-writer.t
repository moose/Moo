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

ok( exception { $foo->get_one('blah') }, 'reader dies on write' );

is( $bar->TWO, '...', 'accessor works for reading' );
$bar->TWO('!!!');
is( $bar->TWO, '!!!', 'accessor works for writing' );

done_testing;
