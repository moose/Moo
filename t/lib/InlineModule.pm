package InlineModule;
use Moo::_strictures;

BEGIN {
  *_HAS_PERLIO = $] >= 5.008 ? sub(){1} : sub(){0};
}

sub import {
  my ($class, %modules) = @_;
  unshift @INC, inc_hook(%modules);
}

sub inc_hook {
  my (%modules) = @_;
  my %files = map {
    (my $file = "$_.pm") =~ s{::}{/}g;
    $file => $modules{$_};
  } keys %modules;

  sub {
    my $module = $files{$_[1]}
      or return;
    inc_module($module);
  }
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
