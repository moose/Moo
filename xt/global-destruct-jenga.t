use strict;
use warnings;

use Test::More;
use IPC::Open3;
use File::Basename qw(dirname);

delete $ENV{PERL5LIB};
delete $ENV{PERL5OPT};
my $pid = open3 my $in, my $fh, undef, $^X, (map "-I$_", @INC), dirname(__FILE__).'/global-destruct-jenga-helper.pl'
  or die "can run jenga helper: $!";
my $out = do { local $/; <$fh> };
close $out;
close $in;
waitpid $pid, 0;
my $err = $?;

is $out, '', 'no error output from global destruct of jenga object';
is $err, 0, 'process ended successfully';

done_testing;
