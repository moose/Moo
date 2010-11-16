package oo;

use strictures 1;
use Moo::_Utils;

sub moo {
  print <<'EOMOO';
 ______
< Moo! >
 ------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
EOMOO
  exit 0;
}

BEGIN {
    my $package;
    sub import {
        moo() if $0 eq '-';
        $package = $_[1] || 'Class';
        if ($package =~ /^\+/) {
            $package =~ s/^\+//;
            _load_module($package);
        }
    }
    use Filter::Simple sub { s/^/package $package;\nuse Moo;\n/; }
}

1;
