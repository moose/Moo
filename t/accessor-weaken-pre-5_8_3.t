use strict;
use warnings;

use File::Spec;
BEGIN {
  $ENV{MOO_TEST_PRE_583} = 1;
}

(my $real_test = File::Spec->rel2abs(__FILE__)) =~ s/-pre-5_8_3//;

unless (defined do $real_test) {
    die "$real_test: $@" if $@;
    die "$real_test: $!" if $!;
}
