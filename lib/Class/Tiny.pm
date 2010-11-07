package Class::Tiny;

use strictures 1;
use Class::Tiny::_Utils;

sub import {
  my $target = caller;
  strictures->import;
  *{_getglob("${target}::extends")} = sub {
    *{_getglob("${target}::ISA")} = \@_;
  };
  *{_getglob("${target}::with")} = sub {
    require Role::Tiny;
    die "Only one role supported at a time by with" if @_ > 1;
    Role::Tiny->apply_role_to_package($_[0], $target);
  };
  foreach my $type (qw(before after around)) {
    *{_getglob "${target}::${type}"} = sub {
      _install_modifier($target, $type, @_);
    };
  }
  {
    no strict 'refs';
    @{"${target}::ISA"} = do {
      require Class::Tiny::Object; ('Class::Tiny::Object');
    } unless @{"${target}::ISA"};
  }
}

1;
