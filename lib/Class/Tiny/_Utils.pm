package Class::Tiny::_Utils;

use strictures 1;
use base qw(Exporter);

our @EXPORT = qw(_getglob _install_modifier);

sub _getglob { no strict 'refs'; \*{$_[0]} }

sub _install_modifier {
  require Class::Method::Modifiers;
  my ($into, $type, $name, $code) = @_;
  my $ref = ref(my $to_modify = $into->can($name));
  if ($ref && $ref =~ /Sub::Defer::Deferred/) {
    require Sub::Defer; undefer($to_modify);
  }
  Class::Method::Modifiers::install_modifier(@_);
}

1;
