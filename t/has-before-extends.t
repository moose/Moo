use strictures 1;
use Test::More;

{
  package Fail1;

  use Moo;

  has 'attr1' => (is => 'ro');

  package Fail2;

  use Moo;

  has 'attr2' => (is => 'ro');

  extends 'Fail1';
}

my $new = Fail2->new({ attr1 => 'value1', attr2 => 'value2' });

is($new->attr1, 'value1', 'inherited attr ok');
is($new->attr2, 'value2', 'subclass attr ok');

done_testing;
