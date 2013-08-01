use strictures 1;
use Test::More;

my $out = `$^X xt/global-destruct-jenga-helper.pl 2>&1`;
is $out, '', 'no errors from global destruct of jenga object';

done_testing;
