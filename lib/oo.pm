package oo;

use strictures 1;
use Moo::_Utils;

BEGIN {
    my $package;
    sub import {
        $package = $_[1] || 'Class';
        if ($package =~ /^\+/) {
            $package =~ s/^\+//;
            _load_module($package);
        }
    }
    use Filter::Simple sub { s/^/package $package;\nuse Moo;\n/; }
}

1;
