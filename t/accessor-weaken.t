use strictures 1;
use Test::More;

{
  package Foo;

  use Moo;

  has one => (is => 'ro', weak_ref => 1);
}

my $ref = \'yay';

my $foo = Foo->new(one => $ref);

is(${$foo->one},'yay', 'value present');
ok(Scalar::Util::isweak($foo->{one}), 'value weakened');

done_testing;
