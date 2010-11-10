package Moo::_Utils;

use strictures 1;
use base qw(Exporter);

our @EXPORT = qw(_getglob _install_modifier _maybe_load_module);

sub _getglob { no strict 'refs'; \*{$_[0]} }

sub _install_modifier {
  my ($into, $type, $name, $code) = @_;
  my $ref = ref(my $to_modify = $into->can($name));

  require Sub::Defer;
  Sub::Defer::undefer_sub($to_modify);

  require Class::Method::Modifiers;
  Class::Method::Modifiers::install_modifier(@_);
}

our %MAYBE_LOADED;

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
