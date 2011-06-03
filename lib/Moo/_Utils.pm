package Moo::_Utils;

sub _getglob { \*{$_[0]} }
sub _getstash { \%{"$_[0]::"} }

BEGIN {
  *lt_5_8_3 = $] < 5.008003
    ? sub () { 1 }
    : sub () { 0 }
  ;
}

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

# _load_module is inlined in Role::Tiny - make sure to copy if you update it.

sub _load_module {
  (my $proto = $_[0]) =~ s/::/\//g;
  return 1 if $INC{"${proto}.pm"};
  # can't just ->can('can') because a sub-package Foo::Bar::Baz
  # creates a 'Baz::' key in Foo::Bar's symbol table
  return 1 if grep !/::$/, keys %{_getstash($_[0])||{}};
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
