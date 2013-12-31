use strictures 1;
use Test::More;

{
  package TypeOMatic;

  use Moo::Role;
  use Sub::Quote;
  use Moo::HandleMoose ();
  use Types::Standard qw(Str);

  has consumed_type => (
    is => 'ro',
    isa => Str,
  );

  package TypeOMatic::Consumer;

  # do this as late as possible to simulate "real" behaviour
  use Moo::HandleMoose;
  use Moose;
  use Types::Standard qw(Str);

  with 'TypeOMatic';

  has direct_type => (
    is => 'ro',
    isa => Str,
  );
}

my $meta = Class::MOP::class_of('TypeOMatic::Consumer');

for my $attr (qw(consumed_type direct_type)) {
  my $type = $meta->get_attribute($attr)->type_constraint;

  isa_ok($type, 'Type::Tiny');
  is($type->name, 'Str');
}

done_testing;
