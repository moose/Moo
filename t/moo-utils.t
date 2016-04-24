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

done_testing;
