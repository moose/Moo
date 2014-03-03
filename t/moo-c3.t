use strictures 1;
use Test::More;

{
  package MyClassRoot;
  use Moo;
  has root => (is => 'ro');
}

{
  package MyClassLeft;
  use Moo;
  extends 'MyClassRoot';
  has left => (is => 'ro');
}

{
  package MyClassRight;
  use Moo;
  extends 'MyClassRoot';
  has right => (is => 'ro');
}

{
  package MyClassChild;
  use Moo;
  extends 'MyClassLeft', 'MyClassRight';
  has child => (is => 'ro');
}

my $o = MyClassChild->new(root => 1, left => 2, right => 3, child => 4);
is $o->root, 1;
is $o->left, 2;
is $o->right, 3;
is $o->child, 4;

done_testing;
