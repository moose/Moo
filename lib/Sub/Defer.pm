package Sub::Defer;

use strictures 1;
use base qw(Exporter);

our @EXPORT = qw(defer undefer);

our %DEFERRED;

sub _getglob { no strict 'refs'; \*{$_[0]} }

sub undefer {
  my ($deferred) = @_;
  my ($target, $maker, $undeferred_ref) = @{
    $DEFERRED{$deferred}||return $deferred
  };
  ${$undeferred_ref} = my $made = $maker->();
  { no warnings 'redefine'; *{_getglob($target)} = $made }
  return $made;
}

sub defer {
  my ($target, $maker) = @_;
  my $undeferred;
  my $deferred_string;
  my $deferred = bless(sub {
    goto &{$undeferred ||= undefer($deferred_string)};
  }, 'Sub::Defer::Deferred');
  $deferred_string = "$deferred";
  $DEFERRED{$deferred} = [ $target, $maker, \$undeferred ];
  *{_getglob $target} = $deferred;
  return $deferred;
}

1;
