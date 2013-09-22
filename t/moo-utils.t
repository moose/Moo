use strictures 1;
use Test::More;
use Test::Fatal;

use Moo::_Utils;

use t::lib::INCModule;

my %files = (
  'Broken/Class.pm' => q{
    use strict;
    use warnings;
    my $f = flub;
  },
);
unshift @INC, sub {
  my $out = $files{$_[1]} or return;
  return inc_module($out);
};

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
}

done_testing;
