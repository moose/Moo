use strict;
use warnings;

use Config ();
BEGIN {
  unless ($Config::Config{useithreads}) {
    print "1..0 # SKIP your perl does not support ithreads\n";
    exit 0;
  }
}
use threads;
use Test::More;
use Type::Tiny;

{
  package TestTTProxy;
  use overload
    q{""}   => sub {
      # construct a "normal" looking stringified ref that represents the same
      # number, but is formatted differently so it won't match the same string
      my $ref_str = overload::AddrRef($_[0]);
      $ref_str =~ s/0x/0x0000/;
      $ref_str;
    },
    q{bool} => sub () { 1 },
    q{&{}}  => sub { my $tt = $_[0]->{tt}; sub { $tt->assert_valid($_[0]) } },
    fallback => 1,
  ;
  sub new {
    my ($class, $tt) = @_;
    my $self = bless { tt => $tt }, $class;
    $Moo::HandleMoose::TYPE_MAP{$self} = sub { $tt };
    return $self;
  }
}

my $str = sub {
  die unless defined $_[0] && !ref $_[0];
};
$Moo::HandleMoose::TYPE_MAP{$str} = sub {
  require Moose::Util::TypeConstraints;
  Moose::Util::TypeConstraints::find_type_constraint("Str");
};

my $int = Type::Tiny->new(
   name       => "Integer",
   constraint => sub { /^(?:-?[1-9][0-9]*|0)$|/ },
   message    => sub { "$_ isn't an integer" },
);

my $int_proxy = TestTTProxy->new($int);

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

is(threads->create(sub {
  my $type = $int_proxy;
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
})->join, 'Type::Tiny', 'Overloaded object inflates to correct type');

done_testing;
