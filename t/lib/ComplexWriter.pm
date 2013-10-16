package ComplexWriter;
use Moo;
use Test::More;
use Test::Fatal;

has "t_$_" => (
  is     => 'rwp',
  $_ => sub { die 'triggered' },
  writer => "set_t_$_",
) for qw(coerce isa trigger);

sub test_with {
  my ($class, $option) = @_;
  my $writer = "set_t_$option";
  like exception { __PACKAGE__->new->$writer( 4 ) }, qr/triggered/, "$option triggered via writer";
}

1;
