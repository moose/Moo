use Test::More tests => 4;

ok(eval {
  package Local::Test::Role1;
  use Moo::Role;
  has [qw/ attr1 attr2 /] => (is => 'ro');
  1;
}, 'has \@attrs works in roles')
  or diag "EVAL FAILED: $@";

ok eval {
  package Local::Test::Class1;
  use Moo;
  with 'Local::Test::Role1';
  has [qw/ attr3 attr4 /] => (is => 'ro');
  1;
}, 'has \@attrs works in classes'
  or diag "EVAL FAILED: $@";

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
