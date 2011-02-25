use strictures 1;
use Test::More;

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

done_testing;
