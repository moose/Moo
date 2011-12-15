package Sub::Quote;

use strictures 1;

sub _clean_eval { eval $_[0] }

use Sub::Defer;
use B 'perlstring';
use Scalar::Util qw(weaken);
use base qw(Exporter);

our @EXPORT = qw(quote_sub unquote_sub quoted_from_sub);

our %QUOTE_OUTSTANDING;

our %QUOTED;

our %WEAK_REFS;

sub capture_unroll {
  my ($from, $captures, $indent) = @_;
  join(
    '',
    map {
      /^([\@\%\$])/
        or die "capture key should start with \@, \% or \$: $_";
      (' ' x $indent).qq{my ${_} = ${1}{${from}->{${\perlstring $_}}};\n};
    } keys %$captures
  );
}

sub inlinify {
  my ($code, $args, $extra, $local) = @_;
  my $do = 'do { '.($extra||'');
  if (my ($code_args, $body) = $code =~ / +my \(([^)]+)\) = \@_;(.*)$/s) {
    if ($code_args eq $args) {
      $do.$body.' }'
    } else {
      $do.'my ('.$code_args.') = ('.$args.'); '.$body.' }';
    }
  } else {
    $do.($local ? 'local ' : '').'@_ = ('.$args.'); '.$code.' }';
  }
}

sub _unquote_all_outstanding {
  return unless %QUOTE_OUTSTANDING;
  my ($assembled_code, @assembled_captures, @localize_these) = '';
  # we sort the keys in order to make debugging more predictable
  foreach my $outstanding (sort keys %QUOTE_OUTSTANDING) {
    my ($name, $code, $captures) = @{$QUOTE_OUTSTANDING{$outstanding}};

    push @localize_these, $name if $name;

    my $make_sub = "{\n";

    if (keys %$captures) {
      my $ass_cap_count = @assembled_captures;
      $make_sub .= capture_unroll("\$_[1][${ass_cap_count}]", $captures, 2);
      push @assembled_captures, $captures;
    }

    my $o_quoted = perlstring $outstanding;
    $make_sub .= (
      $name
          # disable the 'variable $x will not stay shared' warning since
          # we're not letting it escape from this scope anyway so there's
          # nothing trying to share it
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
  my $debug_code = $assembled_code;
  if (@localize_these) {
    $debug_code =
      "# localizing: ".join(', ', @localize_these)."\n"
      .$assembled_code;
    $assembled_code = join("\n",
      (map { "local *${_};" } @localize_these),
      'eval '.perlstring($assembled_code).'; die $@ if $@;'
    );
  } else {
    $ENV{SUB_QUOTE_DEBUG} && warn $assembled_code;
  }
  $assembled_code .= "\n1;";
  {
    local $@;
    unless (_clean_eval $assembled_code, \@assembled_captures) {
      die "Eval went very, very wrong:\n\n${debug_code}\n\n$@";
    }
  }
  $ENV{SUB_QUOTE_DEBUG} && warn $debug_code;
  %QUOTE_OUTSTANDING = ();
}

sub quote_sub {
  # HOLY DWIMMERY, BATMAN!
  # $name => $code => \%captures => \%options
  # $name => $code => \%captures
  # $name => $code
  # $code => \%captures => \%options
  # $code
  my $options =
    (ref($_[-1]) eq 'HASH' and ref($_[-2]) eq 'HASH')
      ? pop
      : {};
  my $captures = pop if ref($_[-1]) eq 'HASH';
  undef($captures) if $captures && !keys %$captures;
  my $code = pop;
  my $name = $_[0];
  my $outstanding;
  my $deferred = defer_sub +($options->{no_install} ? undef : $name) => sub {
    unquote_sub($outstanding);
  };
  $outstanding = "$deferred";
  $QUOTE_OUTSTANDING{$outstanding} = $QUOTED{$outstanding} = [
    $name, $code, $captures
  ];
  weaken($WEAK_REFS{$outstanding} = $deferred);
  return $deferred;
}

sub quoted_from_sub {
  my ($sub) = @_;
  $WEAK_REFS{$sub||''} and $QUOTED{$sub||''};
}

sub unquote_sub {
  my ($sub) = @_;
  _unquote_all_outstanding;
  $QUOTED{$sub}[3];
}

1;

=head1 NAME

Sub::Quote - efficient generation of subroutines via string eval

=head1 SYNOPSIS

 package Silly;

 use Sub::Quote qw(quote_sub unquote_sub quoted_from_sub);

 quote_sub 'Silly::kitty', q{ print "meow" };

 quote_sub 'Silly::doggy', q{ print "woof" };

 my $sound = 0;

 quote_sub 'Silly::dagron',
   q{ print ++$sound % 2 ? 'burninate' : 'roar' },
   { '$sound' => \$sound };

And elsewhere:

 Silly->kitty;  # meow
 Silly->doggy;  # woof
 Silly->dagron; # burninate
 Silly->dagron; # roar
 Silly->dagron; # burninate

=head1 DESCRIPTION

This package provides performant ways to generate subroutines from strings.

=head1 SUBROUTINES

=head2 quote_sub

 my $coderef = quote_sub 'Foo::bar', q{ print $x++ . "\n" }, { '$x' => \0 };

Arguments: ?$name, $code, ?\%captures, ?\%options

C<$name> is the subroutine where the coderef will be installed.

C<$code> is a string that will be turned into code.

C<\%captures> is a hashref of variables that will be made available to the
code.  See the L</SYNOPSIS>'s C<Silly::dagron> for an example using captures.

=head3 options

=over 2

=item * no_install

B<Boolean>.  Set this option to not install the generated coderef into the
passed subroutine name on undefer.

=back

=head2 unquote_sub

 my $coderef = unquote_sub $sub;

Forcibly replace subroutine with actual code.  Note that for performance
reasons all quoted subs declared so far will be globally unquoted/parsed in
a single eval. This means that if you have a syntax error in one of your
quoted subs you may find out when some other sub is unquoted.

If $sub is not a quoted sub, this is a no-op.

=head2 quoted_from_sub

 my $data = quoted_from_sub $sub;

 my ($name, $code, $captures, $compiled_sub) = @$data;

Returns original arguments to quote_sub, plus the compiled version if this
sub has already been unquoted.

Note that $sub can be either the original quoted version or the compiled
version for convenience.

=head2 inlinify

 my $prelude = capture_unroll {
   '$x' => 1,
   '$y' => 2,
 };

 my $inlined_code = inlinify q{
   my ($x, $y) = @_;

   print $x + $y . "\n";
 }, '$x, $y', $prelude;

Takes a string of code, a string of arguments, a string of code which acts as a
"prelude", and a B<Boolean> representing whether or not to localize the
arguments.

=head2 capture_unroll

 my $prelude = capture_unroll {
   '$x' => 1,
   '$y' => 2,
 };

Generates a snippet of code which is suitable to be used as a prelude for
L</inlinify>.  The keys are the names of the variables and the values are (duh)
the values.  Note that references work as values.
