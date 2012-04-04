use strictures 1;
use Test::More;

{
  package TypeOMatic;

  use Moo::Role;
  use Sub::Quote;
  use MooX::Types::MooseLike::Base qw(Str);
  use MooX::Types::MooseLike::Numeric qw(PositiveInt);

  has named_type => (
    is => 'ro',
    isa => Str,
  );

  has named_external_type => (
    is => 'ro',
    isa => PositiveInt,
  );

  package TypeOMatic::Consumer;

  # do this as late as possible to simulate "real" behaviour
  use Moo::HandleMoose;
  use Moose;
  with 'TypeOMatic';
}

my $meta = Class::MOP::class_of('TypeOMatic::Consumer');

my ($str, $positive_int)
  = map $meta->get_attribute($_)->type_constraint->name,
      qw(named_type named_external_type);

is($str, 'Str', 'Built-in Moose type ok');
is(
  $positive_int, 'MooseX::Types::Common::Numeric::PositiveInt',
  'External (MooseX::Types type) ok'
);

done_testing;
