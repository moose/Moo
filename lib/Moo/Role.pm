package Moo::Role;

use strictures 1;
use Moo::_Utils;
use base qw(Role::Tiny);

BEGIN { *INFO = \%Role::Tiny::INFO }

our %INFO;

sub import {
  my $target = caller;
  strictures->import;
  # get symbol table reference
  my $stash = do { no strict 'refs'; \%{"${target}::"} };
  *{_getglob "${target}::has"} = sub {
    my ($name, %spec) = @_;
    ($INFO{$target}{accessor_maker} ||= do {
      require Method::Generate::Accessor;
      Method::Generate::Accessor->new
    })->generate_method($target, $name, \%spec);
    $INFO{$target}{attributes}{$name} = \%spec;
  };
  goto &Role::Tiny::import;
}

sub apply_role_to_package {
  my ($me, $role, $to) = @_;
  $me->SUPER::apply_role_to_package($role, $to);
  $me->_handle_constructor($to, $INFO{$role}{attributes});
}

sub create_class_with_roles {
  my ($me, $superclass, @roles) = @_;

  my $new_name = join('+', $superclass, my $compose_name = join '+', @roles);
  return $new_name if $Role::Tiny::COMPOSED{class}{$new_name};

  require Sub::Quote;

  $me->SUPER::create_class_with_roles($superclass, @roles);

  foreach my $role (@roles) {
    die "${role} is not a Role::Tiny" unless my $info = $INFO{$role};
  }

  $me->_handle_constructor(
    $new_name, { map %{$INFO{$_}{attributes}||{}}, @roles }
  );

  return $new_name;
}

sub _install_modifiers {
  my ($me, $to, $modifiers) = @_;
  foreach my $modifier (@{$modifiers||[]}) {
    _install_modifier($to, @{$modifier});
  }
}

sub _handle_constructor {
  my ($me, $to, $attr_info) = @_;
  return unless $attr_info && keys %$attr_info;
  if ($INFO{$to}) {
    @{$INFO{$to}{attributes}||={}}{keys %$attr_info} = values %$attr_info;
  } else {
    # only fiddle with the constructor if the target is a Moo class
    if ($INC{"Moo.pm"}
        and my $con = Moo->_constructor_maker_for($to)) {
      $con->register_attribute_specs(%$attr_info);
    }
  }
}

1;
