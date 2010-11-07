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
  if (defined($target)) {
    no warnings 'redefine';
    *{_getglob($target)} = $made;
  }
  return $made;
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
  *{_getglob $target} = $deferred if defined($target);
  return $deferred;
}

1;

=pod

=head1 SYNOPSIS

 use Sub::Defer;

 my $deferred = defer_sub 'Logger::time_since_first_log' => sub {
    my $t = time;
    sub { time - $t };
 };

What the above does is set the Logger::time_since_first_log subroutine to be
the codref that was passed to it, but then after it gets run once, it becomes
the returned coderef.

=head1 DESCRIPTION

These subroutines provide the user with a convenient way to defer create of
subroutines and methods until they are first called.

=head1 SUBROUTINES

=head2 defer_sub

 my $coderef = defer_sub $name => sub { ... };

RIBASUSHI FIX ME PLEASE!!!!

Given name to install a subroutine into and a coderef that returns a coderef,
this function will set up the subroutine such that when it is first called it
will be replaced with the returned coderef.

=head2 undefer_sub

 my $coderef = undefer_sub \&Foo::name;

If the passed coderef has been L<deferred|/defer_sub> this will "undefer" it.
If the passed coderef has not been deferred, this will just return it.

If this is confusing, take a look at the example in the L</SYNOPSIS>.
