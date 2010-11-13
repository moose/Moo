package Role::Tiny;

use strict;
use warnings FATAL => 'all';

our %INFO;
our %APPLIED_TO;
our %COMPOSED;

sub _getglob { no strict 'refs'; \*{$_[0]} }

sub _load_module {
  return 1 if $_[0]->can('can');
  (my $proto = $_[0]) =~ s/::/\//g;
  require "${proto}.pm";
  return 1;
}

sub import {
  my $target = caller;
  my $me = $_[0];
  strictures->import;
  # get symbol table reference
  my $stash = do { no strict 'refs'; \%{"${target}::"} };
  # install before/after/around subs
  foreach my $type (qw(before after around)) {
    *{_getglob "${target}::${type}"} = sub {
      require Class::Method::Modifiers;
      push @{$INFO{$target}{modifiers}||=[]}, [ $type => @_ ];
    };
  }
  *{_getglob "${target}::requires"} = sub {
    push @{$INFO{$target}{requires}||=[]}, @_;
  };
  *{_getglob "${target}::with"} = sub {
    die "Only one role supported at a time by with" if @_ > 1;
    $me->apply_role_to_package($_[0], $target);
  };
  # grab all *non-constant* (ref eq 'SCALAR') subs present
  # in the symbol table and store their refaddrs (no need to forcibly
  # inflate constant subs into real subs) - also add '' to here (this
  # is used later)
  @{$INFO{$target}{not_methods}={}}{
    '', map { *$_{CODE}||() } grep !(ref eq 'SCALAR'), values %$stash
  } = ();
  # a role does itself
  $APPLIED_TO{$target} = { $target => undef };
}

sub apply_role_to_package {
  my ($me, $role, $to) = @_;

  _load_module($role);

  die "This is apply_role_to_package" if ref($to);
  die "${role} is not a Role::Tiny" unless my $info = $INFO{$role};

  $me->_check_requires($to, $role, @{$info->{requires}||[]});

  $me->_install_methods($to, $role);

  $me->_install_modifiers($to, $info->{modifiers});

  # only add does() method to classes and only if they don't have one
  if (not $INFO{$to} and not $to->can('does')) {
    *{_getglob "${to}::does"} = \&does_role;
  }

  # copy our role list into the target's
  @{$APPLIED_TO{$to}||={}}{keys %{$APPLIED_TO{$role}}} = ();
}

sub apply_roles_to_object {
  my ($me, $object, @roles) = @_;
  die "No roles supplied!" unless @roles;
  my $class = ref($object);
  bless($object, $me->create_class_with_roles($class, @roles));
  $object;
}

sub create_class_with_roles {
  my ($me, $superclass, @roles) = @_;

  die "No roles supplied!" unless @roles;

  my $new_name = join('+', $superclass, my $compose_name = join '+', @roles);
  return $new_name if $COMPOSED{class}{$new_name};

  foreach my $role (@roles) {
    _load_module($role);
    die "${role} is not a Role::Tiny" unless my $info = $INFO{$role};
  }

  if ($] > 5.010) {
    require mro;
  } else {
    require MRO::Compat;
  }

  my @composable = map $me->_composable_package_for($_), reverse @roles;

  *{_getglob("${new_name}::ISA")} = [ @composable, $superclass ];

  my @info = map +($INFO{$_} ? $INFO{$_} : ()), @roles;

  $me->_check_requires(
    $new_name, $compose_name,
    do { my %h; @h{map @{$_->{requires}||[]}, @info} = (); keys %h }
  );

  *{_getglob "${new_name}::does"} = \&does_role unless $new_name->can('does');

  @{$APPLIED_TO{$new_name}||={}}{
    map keys %{$APPLIED_TO{$_}}, @roles
  } = ();

  $COMPOSED{class}{$new_name} = 1;
  return $new_name;
}

sub _composable_package_for {
  my ($me, $role) = @_;
  my $composed_name = 'Role::Tiny::_COMPOSABLE::'.$role;
  return $composed_name if $COMPOSED{role}{$composed_name};
  $me->_install_methods($composed_name, $role);
  my $base_name = $composed_name.'::_BASE';
  *{_getglob("${composed_name}::ISA")} = [ $base_name ];
  my $modifiers = $INFO{$role}{modifiers}||[];
  my @mod_base;
  foreach my $modified (
    do { my %h; @h{map $_->[1], @$modifiers} = (); keys %h }
  ) {
    push @mod_base, "sub ${modified} { shift->next::method(\@_) }";
  }
  eval(my $code = join "\n", "package ${base_name};", @mod_base);
  die "Evaling failed: $@\nTrying to eval:\n${code}" if $@;
  $me->_install_modifiers($composed_name, $modifiers);
  $COMPOSED{role}{$composed_name} = 1;
  return $composed_name;
}

sub _check_requires {
  my ($me, $to, $name, @requires) = @_;
  if (my @requires_fail = grep !$to->can($_), @requires) {
    # role -> role, add to requires, role -> class, error out
    if (my $to_info = $INFO{$to}) {
      push @{$to_info->{requires}||=[]}, @requires_fail;
    } else {
      die "Can't apply ${name} to ${to} - missing ".join(', ', @requires_fail);
    }
  }
}

sub _concrete_methods_of {
  my ($me, $role) = @_;
  my $info = $INFO{$role};
  $info->{methods} ||= do {
    # grab role symbol table
    my $stash = do { no strict 'refs'; \%{"${role}::"}};
    my $not_methods = $info->{not_methods};
    +{
      # grab all code entries that aren't in the not_methods list
      map {
        my $code = *{$stash->{$_}}{CODE};
        # rely on the '' key we added in import for "no code here"
        exists $not_methods->{$code||''} ? () : ($_ => $code)
      } grep !(ref($stash->{$_}) eq 'SCALAR'), keys %$stash
    };
  };
}

sub methods_provided_by {
  my ($me, $role) = @_;
  die "${role} is not a Role::Tiny" unless my $info = $INFO{$role};
  (keys %{$me->_concrete_methods_of($role)}, @{$info->{requires}||[]});
}

sub _install_methods {
  my ($me, $to, $role) = @_;

  my $info = $INFO{$role};

  my $methods = $me->_concrete_methods_of($role);

  # grab target symbol table
  my $stash = do { no strict 'refs'; \%{"${to}::"}};

  # determine already extant methods of target
  my %has_methods;
  @has_methods{grep
    +((ref($stash->{$_}) eq 'SCALAR') || (*{$stash->{$_}}{CODE})),
    keys %$stash
  } = ();

  foreach my $i (grep !exists $has_methods{$_}, keys %$methods) {
    no warnings 'once';
    *{_getglob "${to}::${i}"} = $methods->{$i};
  }
}

sub _install_modifiers {
  my ($me, $to, $modifiers) = @_;
  if (my $info = $INFO{$to}) {
    push @{$info->{modifiers}}, @{$modifiers||[]};
  } else {
    foreach my $modifier (@{$modifiers||[]}) {
      $me->_install_single_modifier($to, @$modifier);
    }
  }
}

sub _install_single_modifier {
  my ($me, @args) = @_;
  Class::Method::Modifiers::install_modifier(@args);
}

sub does_role {
  my ($package, $role) = @_;
  return exists $APPLIED_TO{$package}{$role};
}

1;
