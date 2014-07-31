use strictures 1;
use Test::More;

my $c_ran;
{
  package Foo;

  use Sub::Quote;
  use Moo;

  has one => (is => 'ro', lazy => 1, default => quote_sub q{ {} });
  has two => (is => 'ro', lazy => 1, builder => '_build_two');
  sub _build_two { {} }
  has three => (is => 'ro', default => quote_sub q{ {} });
  has four => (is => 'ro', builder => '_build_four');
  sub _build_four { {} }
  has five => (is => 'ro', init_arg => undef, default => sub { {} });
  has six => (is => 'ro', builder => 1);
  sub _build_six { {} }
  has seven => (is => 'ro', required => 1, default => quote_sub q{ {} });
  has eight => (is => 'ro', builder => '_build_eight', coerce => sub { $c_ran = 1; $_[0] });
  sub _build_eight { {} }
  has nine => (is => 'lazy', coerce => sub { $c_ran = 1; $_[0] });
  sub _build_nine { {} }
  has ten => (is => 'lazy', default => 5 );
  has eleven => (is => 'ro', default => 5 );
  has twelve => (is => 'lazy', default => 0 );
  has thirteen => (is => 'ro', default => 0 );
  has fourteen => (is => 'ro', required => 1, builder => '_build_fourteen');
  sub _build_fourteen { {} }
  has fifteen => (is => 'lazy', default => undef);

  # DIE handler was leaking into defaults when coercion is on.
  has default_with_coerce => (
      is        => 'rw',
      coerce    => sub { return $_[0] },
      default   => sub { eval { die "blah\n" }; return $@; }
  );

  has default_no_coerce => (
      is        => 'rw',
      default   => sub { eval { die "blah\n" }; return $@; }
  );
}

sub check {
  my ($attr, @h) = @_;

  is_deeply($h[$_], {}, "${attr}: empty hashref \$h[$_]") for 0..1;

  isnt($h[0],$h[1], "${attr}: not the same hashref");
}

check one => map Foo->new->one, 1..2;

check two => map Foo->new->two, 1..2;

check three => map Foo->new->{three}, 1..2;

check four => map Foo->new->{four}, 1..2;

check five => map Foo->new->{five}, 1..2;

check six => map Foo->new->{six}, 1..2;

check seven => map Foo->new->{seven}, 1..2;

check fourteen => map Foo->new->{fourteen}, 1..2;

check eight => map Foo->new->{eight}, 1..2;
ok($c_ran, 'coerce defaults');

$c_ran = 0;

check nine => map Foo->new->nine, 1..2;
ok($c_ran, 'coerce lazy default');

is(Foo->new->ten, 5, 'non-ref default');
is(Foo->new->eleven, 5, 'eager non-ref default');
is(Foo->new->twelve, 0, 'false non-ref default');
is(Foo->new->thirteen, 0, 'eager false non-ref default');
my $foo = Foo->new;
is($foo->fifteen, undef, 'undef default');
ok(exists $foo->{fifteen}, 'undef default is stored');

is( Foo->new->default_with_coerce, "blah\n" );
is( Foo->new->default_no_coerce,   "blah\n" );

done_testing;
