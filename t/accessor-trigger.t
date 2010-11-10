use strictures 1;
use Test::More;

our @tr;

sub run_for {
  my $class = shift;

  @tr = ();

  my $obj = $class->new;

  ok(!@tr, "${class}: trigger not fired with no value");

  $obj = $class->new(one => 1);

  is_deeply(\@tr, [ 1 ], "${class}: trigger fired on new");

  my $res = $obj->one(2);

  is_deeply(\@tr, [ 1, 2 ], "${class}: trigger fired on set");

  is($res, 2, "${class}: return from set ok");

  is($obj->one, 2, "${class}: return from accessor ok");

  is_deeply(\@tr, [ 1, 2 ], "${class}: trigger not fired for accessor as get");
}

{
  package Foo;

  use Moo;

  has one => (is => 'rw', trigger => sub { push @::tr, $_[1] });
}

run_for 'Foo';

{
  package Bar;

  use Sub::Quote;
  use Moo;

  has one => (is => 'rw', trigger => quote_sub q{ push @::tr, $_[1] });
}

run_for 'Bar';

{
  package Baz;

  use Sub::Quote;
  use Moo;

  has one => (
    is => 'rw',
    trigger => quote_sub(q{ push @{$tr}, $_[1] }, { '$tr' => \\@::tr })
  );
}

run_for 'Baz';

done_testing;
