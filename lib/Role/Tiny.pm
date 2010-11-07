package Role::Tiny;

use strictures 1;
use Class::Tiny::_Utils;

our %INFO;
our %APPLIED_TO;

sub import {
  my $target = caller;
  strictures->import;
  # get symbol table reference
  my $stash = do { no strict 'refs'; \%{"${target}::"} };
  # install before/after/around subs
  foreach my $type (qw(before after around)) {
    *{_getglob "${target}::${type}"} = sub {
      push @{$INFO{$target}{modifiers}||=[]}, [ $type => @_ ];
    };
  }
  *{_getglob "${target}::requires"} = sub {
    push @{$INFO{$target}{requires}||=[]}, @_;
  };
  *{_getglob "${target}::with"} = sub {
    die "Only one role supported at a time by with" if @_ > 1;
    Role::Tiny->apply_role_to_package($_[0], $target);
  };
  *{_getglob "${target}::has"} = sub {
    my ($name, %spec) = @_;
    ($INFO{$target}{accessor_maker} ||= do {
      require Method::Generate::Accessor;
      Method::Generate::Accessor->new
    })->generate_method($target, $name, \%spec);
    $INFO{$target}{attributes}{$name} = \%spec;
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
  my ($class, $role, $to) = @_;
  die "This is apply_role_to_package" if ref($to);
  die "Not a Role::Tiny" unless my $info = $INFO{$role};
  my $methods = $info->{methods} ||= do {
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
  # grab target symbol table
  my $stash = do { no strict 'refs'; \%{"${to}::"}};
  # determine already extant methods of target
  my %has_methods;
  @has_methods{grep
    +((ref($stash->{$_}) eq 'SCALAR') || (*{$stash->{$_}}{CODE})),
    keys %$stash
  } = ();
  if (my @requires_fail
        = grep !exists $has_methods{$_}, @{$info->{requires}||[]}) {
    # role -> role, add to requires, role -> class, error out
    if (my $to_info = $INFO{$to}) {
      push @{$to_info->{requires}||=[]}, @requires_fail;
    } else {
      die "Can't apply ${role} to ${to} - missing ".join(', ', @requires_fail);
    }
  }

  my @to_install = grep !exists $has_methods{$_}, keys %$methods;
  foreach my $i (@to_install) {
    no warnings 'once';
    *{_getglob "${to}::${i}"} = $methods->{$i};
  }

  foreach my $modifier (@{$info->{modifiers}||[]}) {
    _install_modifier($to, @{$modifier});
  }

  # only add does() method to classes and only if they don't have one
  if (not $INFO{$to} and not $to->can('does')) {
    ${_getglob "${to}::does"} = \&does_role;
  }

  if (my $attr_info = $info->{attributes}) {
    if ($INFO{$to}) {
      @{$INFO{$to}{attributes}||={}}{keys %$attr_info} = values %$attr_info;
    } else {
      my $con = $Class::Tiny::MAKERS{$to}{constructor} ||= do {
        require Method::Generate::Constructor;
        Method::Generate::Constructor
          ->new(package => $to)
          ->install_delayed
          ->register_attribute_specs(do {
            my @spec;
            if (my $super = do { no strict 'refs'; ${"${to}::ISA"}[0] }) {
              if (my $con = $Class::Tiny::MAKERS{$super}{constructor}) {
                @spec = %{$con->all_attribute_specs};
              }
            }
            @spec;
          });
      };
      $con->register_attribute_specs(%$attr_info);
    }
  }

  # copy our role list into the target's
  @{$APPLIED_TO{$to}||={}}{keys %{$APPLIED_TO{$role}}} = ();
}

sub does_role {
  my ($package, $role) = @_;
  return exists $APPLIED_TO{$package}{$role};
}

1;
