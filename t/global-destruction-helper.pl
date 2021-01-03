use strict;
use warnings;

use POSIX ();

my $exit_value = shift;

BEGIN {
    package Bar;
    use Moo;

    sub DEMOLISH {
        my ($self, $gd) = @_;
        if ($gd) {
          POSIX::_exit($exit_value);
        }
    }
}

our $bar = Bar->new;
