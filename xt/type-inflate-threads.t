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

my $str = sub {
  die unless defined $_[0] && !ref $_[0];
};
no warnings 'once';
$Moo::HandleMoose::TYPE_MAP{$str} = sub {
  require Moose::Util::TypeConstraints;
  Moose::Util::TypeConstraints::find_type_constraint("Str");
};
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

done_testing;
