use strictures 1;
use Test::More;
use Moo::_Utils;

ok(Moo::_Utils::lt_5_8_3, "pretending to be pre-5.8.3")
    if $ENV{MOO_TEST_PRE_583};

{
  package Foo;

  use Moo;

  has one => (is => 'rw', weak_ref => 1);
  has four=> (is => 'rw', weak_ref => 1, writer => 'set_four');

  package Foo2;

  use Moo;

  our $preexist = {};
  has one => (is => 'rw', lazy => 1, weak_ref => 1, default => sub { $preexist });
  has two => (is => 'rw', lazy => 1, weak_ref => 1, default => sub { {} });
}

my $ref = {};
my $foo = Foo->new(one => $ref);
is($foo->one, $ref, 'value present');
ok(Scalar::Util::isweak($foo->{one}), 'value weakened');
undef $ref;
ok(!defined $foo->{one}, 'weak value gone');

my $foo2 = Foo2->new;
ok(my $ref2 = $foo2->one, 'external value returned');
is($foo2->one, $ref2, 'value maintained');
ok(Scalar::Util::isweak($foo2->{one}), 'value weakened');
is($foo2->one($ref2), $ref2, 'value returned from setter');
undef $ref2;
ok(!defined $foo->{one}, 'weak value gone');

is($foo2->two, undef, 'weak+lazy ref not returned');
is($foo2->{two}, undef, 'internal value not set');
my $ref3 = {};
is($foo2->two($ref3), $ref3, 'value returned from setter');
undef $ref3;
ok(!defined $foo->{two}, 'weak value gone');

my $ref4 = {};
my $foo4 = Foo->new;
$foo4->set_four($ref4);
is($foo4->four, $ref4, 'value present');
ok(Scalar::Util::isweak($foo4->{four}), 'value weakened');
undef $ref4;
ok(!defined $foo4->{four}, 'weak value gone');


# test readonly SVs
sub mk_ref { \ 'yay' };
my $foo_ro = eval { Foo->new(one => mk_ref()) };
if ($] < 5.008003) {
  like(
    $@,
    qr/\QReference to readonly value in "one" can not be weakened on Perl < 5.8.3/,
    'Expected exception thrown on old perls'
  );
}
elsif ($^O eq 'cygwin' and $] < 5.012000) {
  SKIP: { skip 'Static coderef reaping seems nonfunctional on cygwin < 5.12', 1 }
}
else {
  is(${$foo_ro->one},'yay', 'value present');
  ok(Scalar::Util::isweak($foo_ro->{one}), 'value weakened');

  { no warnings 'redefine'; *mk_ref = sub {} }
  ok (!defined $foo_ro->{one}, 'optree reaped, ro static value gone');
}

done_testing;
