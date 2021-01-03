use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moo::HandleMoose;

foreach my $class (qw(
  Method::Generate::Accessor
  Method::Generate::Constructor
  Method::Generate::BuildAll
  Method::Generate::DemolishAll
)) {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  is exception {
    (my $file = "$class.pm") =~ s{::}{/}g;
    require $file;
    Moo::HandleMoose::inject_real_metaclass_for($class);
  }, undef,
    "No exceptions inflating $class";
  ok !@warnings, "No warnings inflating $class"
    or diag "Got warnings: @warnings";
}

done_testing;
