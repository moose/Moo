use strictures 1;
use Test::More;

my @result;

{
  package Foo;

  use Moo;

  my @isa = (isa => sub { push @result, 'isa', $_[0] });
  my @trigger = (trigger => sub { push @result, 'trigger', $_[1] });
  sub _mkdefault {
    my $val = shift;
    (default => sub { push @result, 'default', $val; $val; })
  }

  has a1 => (
    is => 'rw', @isa
  );
  has a2 => (
    is => 'rw', @isa, @trigger
  );
  has a3 => (
    is => 'rw', @isa, @trigger
  );
  has a4 => (
    is => 'rw', @trigger, _mkdefault('a4')
  );
  has a5 => (
    is => 'rw', @trigger, _mkdefault('a5')
  );
  has a6 => (
    is => 'rw', @isa, @trigger, _mkdefault('a6')
  );
  has a7 => (
    is => 'rw', @isa, @trigger, _mkdefault('a7')
  );
}

my $foo = Foo->new(a1 => 'a1', a2 => 'a2', a4 => 'a4', a6 => 'a6');

is_deeply(
  \@result,
  [ qw(isa a1 isa a2 trigger a2 trigger a4 default a5 isa a6 trigger a6
    default a7 isa a7) ],
  'Stuff fired in expected order'
);

done_testing;
