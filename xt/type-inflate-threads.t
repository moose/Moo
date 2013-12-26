use Config;
BEGIN {
  unless ($Config{useithreads}) {
    print "1..0 # SKIP your perl does not support ithreads\n";
    exit 0;
  }
}
use threads;
use strictures 1;
use Test::More;
use Type::Tiny;

my $str = sub {
  die unless defined $_[0] && !ref $_[0];
};
no warnings 'once';
$Moo::HandleMoose::TYPE_MAP{$str} = sub {
  require Moose::Util::TypeConstraints;
  Moose::Util::TypeConstraints::find_type_constraint("Str");
};

my $int = Type::Tiny->new(
   name       => "Integer",
   constraint => sub { /^(?:-?[1-9][0-9]*|0)$|/ },
   message    => sub { "$_ isn't an integer" },
);
require Moo;

is(threads->create(sub {
  my $type = $str;
  eval q{
    package TypeOMatic;
    use Moo;
    has str_type => (
      is => 'ro',
      isa => $type,
    );
    1;
  } or die $@;

  require Moose;
  my $meta = Class::MOP::class_of('TypeOMatic');
  my $str_name = $meta->get_attribute("str_type")->type_constraint->name;
  $str_name;
})->join, 'Str', 'Type created outside thread properly inflated');

is(threads->create(sub {
  my $type = $int;
  eval q{
    package TypeOMatic;
    use Moo;
    has int_type => (
      is => 'ro',
      isa => $type,
    );
    1;
  } or die $@;

  require Moose;
  my $meta = Class::MOP::class_of('TypeOMatic');
  my $int_class = ref $meta->get_attribute("int_type")->type_constraint;
  $int_class;
})->join, 'Type::Tiny', 'Type::Tiny created outside thread inflates to self');

done_testing;
