package Class::Tiny::_Utils;

use strictures 1;
use base qw(Exporter);

our @EXPORT = qw(_getglob _install_modifier);

sub _getglob { no strict 'refs'; \*{$_[0]} }

sub _install_modifier {
  require Class::Method::Modifiers;
  my ($into, $type, $name, $code) = @_;
  my $ref = ref(my $to_modify = $into->can($name));

  # if it isn't CODE, then either we're about to die, or it's a blessed
  # coderef - if it's a blessed coderef it might be deferred, and the
  # user's already doing something clever so a minor speed hit is meh.

  if ($ref && $ref ne 'CODE') {
    require Sub::Defer; Sub::Defer::undefer_sub($to_modify);
  }
  Class::Method::Modifiers::install_modifier(@_);
}

1;
