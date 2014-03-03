use strictures 1;
use Test::More;

my $out = `"$^X" xt/global-destruct-jenga-helper.pl 2>&1`;
my $err = $?;
is $out, '', 'no error output from global destruct of jenga object';
is $err, 0, 'process ended successfully';

done_testing;
