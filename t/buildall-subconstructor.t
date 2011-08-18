use strictures 1;
use Test::More;

my @ran;

{
  package Foo; use Moo; sub BUILD { push @ran, 'Foo' }
  package Bar; use Moo; extends 'Foo'; sub BUILD { push @ran, 'Bar' }
  package Baz; use Moo; extends 'Bar';
  package Quux; use Moo; extends 'Baz'; sub BUILD { push @ran, 'Quux' }
}

{
  package Fleem;
  use Moo;
  extends 'Quux';
  has 'foo' => (is => 'ro');
  sub BUILD { push @ran, $_[0]->foo, $_[1]->{bar} }
}

{
  package Odd1;
  use Moo;
  has 'odd1' => (is => 'ro');
  sub BUILD { push @ran, 'Odd1' }
  package Odd2;
  use Moo;
  extends 'Odd1';
  package Odd3;
  use Moo;
  extends 'Odd2';
  has 'odd3' => (is => 'ro');
  sub BUILD { push @ran, 'Odd3' }
}

{
  package Sub1;
  use Moo;
  has 'foo' => (is => 'ro');
  package Sub2;
  use Moo;
  extends 'Sub1';
  sub BUILD { push @ran, "sub2" }
}

my @tests = (
    'Foo' => {
        ran => [qw( Foo )],
    },
    'Bar' => {
        ran => [qw( Foo Bar )],
    },
    'Baz' => {
        ran => [qw( Foo Bar )],
    },
    'Quux' => {
        ran => [qw( Foo Bar Quux )],
    },
    'Fleem' => {
        ran => [qw( Foo Bar Quux Fleem1 Fleem2 )],
        args => [ foo => 'Fleem1', bar => 'Fleem2' ],
    },
    'Odd1' => {
        ran => [qw( Odd1 )],
    },
    'Odd2' => {
        ran => [qw( Odd1 )],
    },
    'Odd3' => {
        ran => [qw( Odd1 Odd3 )],
        args => [ odd1 => 1, odd3 => 3 ],
    },
    'Sub1' => {
        ran => [],
    },
    'Sub2' => {
        ran => [qw( sub2 )],
    },
);

while ( my ($class, $conf) = splice(@tests,0,2) ) {
    my $o = $class->new( @{ $conf->{args} || [] } );
    isa_ok($o, $class);
    is_deeply(\@ran, $conf->{ran}, 'BUILDs ran in order');
    @ran = ();
}

done_testing;
