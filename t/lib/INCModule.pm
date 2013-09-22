package t::lib::INCModule;
use strictures 1;
use base qw(Exporter);
our @EXPORT = qw(inc_module);

BEGIN {
  *_HAS_PERLIO = $] >= 5.008 ? sub(){1} : sub(){0};
}

sub inc_module {
  my $code = $_[0];
  if (_HAS_PERLIO) {
    open my $fh, '<', \$code
      or die "error loading module: $!";
    return $fh;
  }
  else {
    return sub {
      return 0 unless length $code;
      $code =~ s/^([^\n]*\n?)//;
      $_ = $1;
      return 1;
    };
  }
}

1;
