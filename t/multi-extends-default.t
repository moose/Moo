use Test::More;
use Devel::Dwarn;
{
  package P1;
  use Moo;
  has 'a' => ( is => 'rw', default => 'P1a' );

  package P2;
  use Moo;
  has 'b' => ( is => 'rw', default => 'P2b' );

  package C;
  use Moo;
  extends qw(P1 P2);

  package D;
  use Moo;
  extends qw(C);
}

for my $class (qw(C D)) {
  {
    my $c = $class->new;
    is $c->a, 'P1a', 'default from P1';
    is $c->b, 'P2b', 'default from P2';
  }
  {
    my $c = $class->new(a => 'foo');
    is $c->a, 'foo', 'init_arg for P1';
    is $c->b, 'P2b', 'default from P2';
  }
  {
    my $c = $class->new(b => 'bar');
    is $c->a, 'P1a', 'default from P1';
    is $c->b, 'bar', 'init_arg for P2';
  }
  {
    my $c = $class->new(a => 'foo', b => 'bar');
    is $c->a, 'foo', 'init_arg for P1';
    is $c->b, 'bar', 'init_arg for P2';
  }

}

done_testing;
