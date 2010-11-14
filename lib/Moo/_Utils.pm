package Moo::_Utils;

sub _getglob { \*{$_[0]} }

use strictures 1;
use base qw(Exporter);

our @EXPORT = qw(_getglob _install_modifier _load_module _maybe_load_module);

sub _install_modifier {
  my ($into, $type, $name, $code) = @_;

  if (my $to_modify = $into->can($name)) { # CMM will throw for us if not
    require Sub::Defer;
    Sub::Defer::undefer_sub($to_modify);
  }

  Class::Method::Modifiers::install_modifier(@_);
}

our %MAYBE_LOADED;

sub _load_module {
  return 1 if $_[0]->can('can');
  (my $proto = $_[0]) =~ s/::/\//g;
  require "${proto}.pm";
  return 1;
}

sub _maybe_load_module {
  return $MAYBE_LOADED{$_[0]} if exists $MAYBE_LOADED{$_[0]};
  (my $proto = $_[0]) =~ s/::/\//g;
  if (eval { require "${proto}.pm"; 1 }) {
    $MAYBE_LOADED{$_[0]} = 1;
  } else {
    if (exists $INC{"${proto}.pm"}) {
      warn "$_[0] exists but failed to load with error: $@";
    }
    $MAYBE_LOADED{$_[0]} = 0;
  }
  return $MAYBE_LOADED{$_[0]};
}

1;
