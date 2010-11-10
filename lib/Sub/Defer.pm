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
