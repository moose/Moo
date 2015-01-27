use Moo::_strictures;
use Test::More;
use Test::Fatal;

use Moo::HandleMoose;
use Module::Runtime qw(use_module);

foreach my $class (qw(
  Method::Generate::Accessor
  Method::Generate::Constructor
  Method::Generate::BuildAll
  Method::Generate::DemolishAll
)) {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  is exception {
    Moo::HandleMoose::inject_real_metaclass_for(use_module($class))
  }, undef,
    "No exceptions inflating $class";
  ok !@warnings, "No warnings inflating $class"
    or diag "Got warnings: @warnings";
}

done_testing;
