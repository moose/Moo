package Sub::Quote;

use strictures 1;

sub _clean_eval { eval $_[0] }

use Sub::Defer;
use B 'perlstring';
use base qw(Exporter);

our @EXPORT = qw(quote_sub unquote_sub);

our %QUOTE_OUTSTANDING;

our %QUOTED;

sub _unquote_all_outstanding {
  return unless %QUOTE_OUTSTANDING;
  my ($assembled_code, @assembled_captures, @localize_these) = '';
  foreach my $outstanding (keys %QUOTE_OUTSTANDING) {
    my ($name, $code, $captures) = @{$QUOTE_OUTSTANDING{$outstanding}};

    push @localize_these, $name if $name;

    my $make_sub = "{\n";

    if (keys %$captures) {
      my $ass_cap_count = @assembled_captures;
      $make_sub .= join(
	"\n",
	map {
	  /^([\@\%\$])/
	    or die "capture key should start with \@, \% or \$: $_";
	  qq{  my ${_} = ${1}{\$_[1][${ass_cap_count}]{${\perlstring $_}}};\n};
	} keys %$captures
      );
      push @assembled_captures, $captures;
    }

    my $o_quoted = perlstring $outstanding;
    $make_sub .= (
      $name
        ? "  no warnings 'closure';\n  sub ${name} {\n"
	: "  \$Sub::Quote::QUOTED{${o_quoted}}[3] = sub {\n"
    );
    $make_sub .= $code;
    $make_sub .= "  }".($name ? '' : ';')."\n";
    if ($name) {
      $make_sub .= "  \$Sub::Quote::QUOTED{${o_quoted}}[3] = \\&${name}\n";
    }
    $make_sub .= "}\n";
    $assembled_code .= $make_sub;
  }
  if (@localize_these) {
    $assembled_code = join("\n",
      (map { "local *${_};" } @localize_these),
      'eval '.perlstring $assembled_code
    );
  }
  $ENV{SUB_QUOTE_DEBUG} && warn $assembled_code;
  _clean_eval $assembled_code, \@assembled_captures;
  if ($@) {
    die "Eval went very, very wrong:\n\n${assembled_code}\n\n$@";
  }
  %QUOTE_OUTSTANDING = ();
}

sub quote_sub {
  # HOLY DWIMMERY, BATMAN!
  # $name => $code => \%captures
  # $name => $code
  # $code => \%captures
  # $code
  my $captures = pop if ref($_[-1]) eq 'HASH';
  my $code = pop;
  my $name = $_[0];
  my $outstanding;
  my $deferred = defer_sub $name => sub {
    unquote_sub($outstanding);
  };
  $outstanding = "$deferred";
  $QUOTE_OUTSTANDING{$outstanding} = $QUOTED{$outstanding} = [
    $name, $code, $captures
  ];
  return $deferred;
}

sub quoted_from_sub {
  my ($sub) = @_;
  $QUOTED{$sub};
}

sub unquote_sub {
  my ($sub) = @_;
  _unquote_all_outstanding;
  $QUOTED{$sub}[3];
}

1;
