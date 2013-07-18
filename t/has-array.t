use strictures;
use Test::More;
use Test::Fatal;

is(exception {
  package Local::Test::Role1;
  use Moo::Role;
  has [qw/ attr1 attr2 /] => (is => 'ro');
}, undef, 'has \@attrs works in roles');

is(exception {
  package Local::Test::Class1;
  use Moo;
  with 'Local::Test::Role1';
  has [qw/ attr3 attr4 /] => (is => 'ro');
}, undef, 'has \@attrs works in classes');

my $obj = new_ok 'Local::Test::Class1' => [
  attr1  => 1,
  attr2  => 2,
  attr3  => 3,
  attr4  => 4,
];

can_ok(
  $obj,
  qw( attr1 attr2 attr3 attr4 ),
);

like(exception {
  package Local::Test::Role2;
  use Moo::Role;
  has [qw/ attr1 attr2 /] => (is => 'ro', 'isa');
}, qr/^Invalid options for 'attr1', 'attr2' attribute\(s\): even number of arguments expected, got 3/,
  'correct exception when has given bad parameters in role');

like(exception {
  package Local::Test::Class2;
  use Moo;
  has [qw/ attr3 attr4 /] => (is => 'ro', 'isa');
}, qr/^Invalid options for 'attr3', 'attr4' attribute\(s\): even number of arguments expected, got 3/,
  'correct exception when has given bad parameters in class');

done_testing;
