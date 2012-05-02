use strictures 1;
use Test::More;
use Test::Fatal;

my $test         = "test";
my $lazy_default = "lazy_default";

{
  package Foo;

  use Moo;

  has rwp  => (is => 'rwp');
  has lazy => (is => 'lazy');
  sub _build_lazy    { $test }
  has lazy_default => (is => 'lazy', default => sub { $lazy_default });
}

my $foo = Foo->new;

# rwp
{
  is $foo->rwp, undef, "rwp value starts out undefined";
  ok exception { $foo->rwp($test) }, "rwp is read_only";
  is exception { $foo->_set_rwp($test) }, undef, "rwp can be set by writer";
  is $foo->rwp, $test, "rwp value was set by writer";
}

# lazy
{
  is $foo->{lazy}, undef, "lazy value storage is undefined";
  is $foo->lazy, $test, "lazy value returns test value when called";
  ok exception { $foo->lazy($test) }, "lazy is read_only";
}

# lazy + default
{
  is $foo->{lazy_default}, undef, "lazy_default value storage is undefined";
  is $foo->lazy_default, $lazy_default, "lazy_default value returns test value when called";
  ok exception { $foo->lazy_default($test) }, "lazy_default is read_only";
}

done_testing;
