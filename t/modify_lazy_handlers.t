use strict;
use warnings;

use Test::More;

BEGIN {
  package ClassicObject;

  sub new {
      my ($class, %args) = @_;
      bless \%args, 'ClassicObject';
  }

  sub connect { 'a' }
}

BEGIN {
  package MooObjectWithDelegate;
  use Scalar::Util ();
  use Moo;

  has 'delegated' => (
    is => 'ro',
    isa => sub {
      do { $_[0] && Scalar::Util::blessed($_[0]) }
        or die "Not an Object!";
    },
    lazy => 1,
    builder => '_build_delegated',
    handles => [qw/connect/],
  );

  sub _build_delegated {
    my $self = shift;
    return ClassicObject->new;
  }

  around 'connect', sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(@args) . 'b';
  };

  around 'connect', sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(@args) . 'c';
  };
}

ok my $moo_object = MooObjectWithDelegate->new,
  'got object';

is $moo_object->connect, 'abc',
  'got abc';

done_testing;
