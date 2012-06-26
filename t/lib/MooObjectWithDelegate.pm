package MooObjectWithDelegate;
use ClassicObject;
use Moo;

has 'delegated' => (
  is => 'ro',
  isa => sub {
    do { $_[0] && blessed($_[0]) }
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


1;
