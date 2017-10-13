use Moo::_strictures;
use Test::More;
use Test::Fatal;
use Moo::_Utils;
use lib 't/lib';
use InlineModule (
  'Broken::Class' => q{
    use strict;
    use warnings;
    my $f = flub;
  },
);

{
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  is exception {
    ok !_maybe_load_module('Broken::Class'),
      '_maybe_load_module returns false for broken modules';
  }, undef, "_maybe_load_module doesn't die on broken modules";
  like $warn[0], qr/Broken::Class exists but failed to load with error/,
    '_maybe_load_module errors become warnings';
  _maybe_load_module('Broken::Class');
  is scalar @warn, 1,
    '_maybe_load_module only warns once per module';
  ok !_maybe_load_module('Missing::Module::A'.int rand 10**10),
    '_maybe_load_module returns false for missing module';
  is scalar @warn, 1,
    " ... and doesn't warn";
}

{
  local @INC = ();
  {
    package Module::WithVariable;
    our $VARIABLE = 219;
  }
  like exception { Moo::_Utils::_load_module('Module::WithVariable') },
    qr{^Can't locate Module/WithVariable.pm },
    '_load_module: inline package with only variable not treated as loaded';

  {
    package Module::WithSub;
    sub glorp { $_[0] + 1 }
  }
  is exception { Moo::_Utils::_load_module('Module::WithSub') }, undef,
    '_load_module: inline package with sub treated as loaded';

  {
    package Module::WithConstant;
    use constant GORP => "GLUB";
  }
  is exception { Moo::_Utils::_load_module('Module::WithConstant') }, undef,
    '_load_module: inline package with constant treated as loaded';

  {
    package Module::WithListConstant;
    use constant GORP => "GLUB", "BOGGLE";
  }
  is exception { Moo::_Utils::_load_module('Module::WithListConstant') }, undef,
    '_load_module: inline package with constant treated as loaded';

  {
    package Module::WithBEGIN;
    my $var;
    BEGIN { $var = 1 }
  }
  like exception { Moo::_Utils::_load_module('Module::WithBEGIN') },
    qr{^Can't locate Module/WithBEGIN.pm },
    '_load_module: inline package with only BEGIN not treated as loaded';

  {
    package Module::WithSubPackage;
    package Module::WithSubPackage::SubPackage;
    our $grop = 1;
    sub grop { 1 }
  }
  like exception { Moo::_Utils::_load_module('Module::WithSubPackage') },
    qr{^Can't locate Module/WithSubPackage.pm },
    '_load_module: inline package with sub package not treated as loaded';

}

done_testing;
