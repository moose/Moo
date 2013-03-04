package Sub::Defer;

use strictures 1;
use base qw(Exporter);
use Moo::_Utils;

our @EXPORT = qw(defer_sub undefer_sub);

our %DEFERRED;

sub undefer_sub {
  my ($deferred) = @_;
  my ($target, $maker, $undeferred_ref) = @{
    $DEFERRED{$deferred}||return $deferred
  };
  ${$undeferred_ref} = my $made = $maker->();

  # make sure the method slot has not changed since deferral time
  if (defined($target) && $deferred eq *{_getglob($target)}{CODE}||'') {
    no warnings 'redefine';

    # I believe $maker already evals with the right package/name, so that
    # _install_coderef calls are not necessary --ribasushi
    *{_getglob($target)} = $made;
  }
  push @{$DEFERRED{$made} = $DEFERRED{$deferred}}, $made;

  return $made;
}

sub defer_info {
  my ($deferred) = @_;
  $DEFERRED{$deferred||''};
}

sub defer_sub {
  my ($target, $maker) = @_;
  my $undeferred;
  my $deferred_string;
  my $deferred = sub {
    goto &{$undeferred ||= undefer_sub($deferred_string)};
  };
  $deferred_string = "$deferred";
  $DEFERRED{$deferred} = [ $target, $maker, \$undeferred ];
  _install_coderef($target => $deferred) if defined $target;
  return $deferred;
}

1;

=head1 NAME

Sub::Defer - defer generation of subroutines until they are first called

=head1 SYNOPSIS

 use Sub::Defer;

 my $deferred = defer_sub 'Logger::time_since_first_log' => sub {
    my $t = time;
    sub { time - $t };
 };

  Logger->time_since_first_log; # returns 0 and replaces itself
  Logger->time_since_first_log; # returns time - $t

=head1 DESCRIPTION

These subroutines provide the user with a convenient way to defer creation of
subroutines and methods until they are first called.

=head1 SUBROUTINES

=head2 defer_sub

 my $coderef = defer_sub $name => sub { ... };

This subroutine returns a coderef that encapsulates the provided sub - when
it is first called, the provided sub is called and is -itself- expected to
return a subroutine which will be goto'ed to on subsequent calls.

If a name is provided, this also installs the sub as that name - and when
the subroutine is undeferred will re-install the final version for speed.

=head2 undefer_sub

 my $coderef = undefer_sub \&Foo::name;

If the passed coderef has been L<deferred|/defer_sub> this will "undefer" it.
If the passed coderef has not been deferred, this will just return it.

If this is confusing, take a look at the example in the L</SYNOPSIS>.

=head1 SUPPORT

See L<Moo> for support and contact informations.

=head1 AUTHORS

See L<Moo> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Moo> for the copyright and license.
