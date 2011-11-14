package Role::Tiny;

sub _getglob { \*{$_[0]} }
sub _getstash { \%{"$_[0]::"} }

use strict;
use warnings FATAL => 'all';

our %INFO;
our %APPLIED_TO;
our %COMPOSED;

# inlined from Moo::_Utils - update that first.

sub _load_module {
  (my $proto = $_[0]) =~ s/::/\//g;
  return 1 if $INC{"${proto}.pm"};
  # can't just ->can('can') because a sub-package Foo::Bar::Baz
  # creates a 'Baz::' key in Foo::Bar's symbol table
  return 1 if grep !/::$/, keys %{_getstash($_[0])||{}};
  { local $@; require "${proto}.pm"; }
  return 1;
}

{ # \[] is REF, not SCALAR. \v1 is VSTRING (thanks to doy for that one)
  my %reftypes = map +($_ => 1), qw(SCALAR REF VSTRING);
  sub _is_scalar_ref { $reftypes{ref($_[0])} }
}

sub import {
  my $target = caller;
  my $me = shift;
  strictures->import;
  return if $INFO{$target}; # already exported into this package
  # get symbol table reference
  my $stash = do { no strict 'refs'; \%{"${target}::"} };
  # install before/after/around subs
  foreach my $type (qw(before after around)) {
    *{_getglob "${target}::${type}"} = sub {
      { local $@; require Class::Method::Modifiers; }
      push @{$INFO{$target}{modifiers}||=[]}, [ $type => @_ ];
    };
  }
  *{_getglob "${target}::requires"} = sub {
    push @{$INFO{$target}{requires}||=[]}, @_;
  };
  *{_getglob "${target}::with"} = sub {
    die "Only one role supported at a time by with" if @_ > 1;
    $me->apply_role_to_package($target, $_[0]);
  };
  # grab all *non-constant* (stash slot is not a scalarref) subs present
  # in the symbol table and store their refaddrs (no need to forcibly
  # inflate constant subs into real subs) - also add '' to here (this
  # is used later)
  @{$INFO{$target}{not_methods}={}}{
    '', map { *$_{CODE}||() } grep !_is_scalar_ref($_), values %$stash
  } = ();
  # a role does itself
  $APPLIED_TO{$target} = { $target => undef };
}

sub apply_role_to_package {
  my ($me, $to, $role) = @_;

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

  my $new_name = join(
    '__WITH__', $superclass, my $compose_name = join '__AND__', @roles
  );

  return $new_name if $COMPOSED{class}{$new_name};

  foreach my $role (@roles) {
    _load_module($role);
    die "${role} is not a Role::Tiny" unless my $info = $INFO{$role};
  }

  if ($] >= 5.010) {
    { local $@; require mro; }
  } else {
    { local $@; require MRO::Compat; }
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
  {
    local $@;
    eval(my $code = join "\n", "package ${base_name};", @mod_base);
    die "Evaling failed: $@\nTrying to eval:\n${code}" if $@;
  }
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
      } grep !_is_scalar_ref($stash->{$_}), keys %$stash
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
    +(_is_scalar_ref($stash->{$_}) || *{$stash->{$_}}{CODE}),
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
  my ($proto, $role) = @_;
  return exists $APPLIED_TO{ref($proto)||$proto}{$role};
}

1;

=head1 NAME

Role::Tiny - Roles. Like a nouvelle cusine portion size slice of Moose.

=head1 SYNOPSIS

 package Some::Role;

 use Role::Tiny;

 sub foo { ... }

 sub bar { ... }

 1;

else where

 package Some::Class;

 use Role::Tiny::With;

 # bar gets imported, but not foo
 with 'Some::Role';

 sub foo { ... }

 1;

=head1 DESCRIPTION

C<Role::Tiny> is a minimalist role composition tool.

=head1 ROLE COMPOSITION

Role composition can be thought of as much more clever and meaningful multiple
inheritance.  The basics of this implementation of roles is:

=over 2

=item *

If a method is already defined on a class, that method will not be composed in
from the role.

=item *

If a method that the role L</requires> to be implemented is not implemented,
role application will fail loudly.

=back

Unlike L<Class::C3>, where the B<last> class inherited from "wins," role
composition is the other way around, where first wins.  In a more complete
system (see L<Moose>) roles are checked to see if they clash.  The goal of this
is to be much simpler, hence disallowing composition of multiple roles at once.

=head1 METHODS

=head2 apply_role_to_package

 Role::Tiny->apply_role_to_package('Some::Package', 'Some::Role');

Composes role with package.  See also L<Role::Tiny::With>.

=head2 apply_roles_to_object

 Role::Tiny->apply_roles_to_object($foo, qw(Some::Role1 Some::Role2));

Composes roles in order into object directly.  Object is reblessed into the
resulting class.

=head2 create_class_with_roles

 Role::Tiny->create_class_with_roles('Some::Base', qw(Some::Role1 Some::Role2));

Creates a new class based on base, with the roles composed into it in order.
New class is returned.

=head1 SUBROUTINES

=head2 does_role

 if (Role::Tiny::does_role($foo, 'Some::Role')) {
   ...
 }

Returns true if class has been composed with role.

This subroutine is also installed as ->does on any class a Role::Tiny is
composed into unless that class already has an ->does method, so

  if ($foo->does_role('Some::Role')) {
    ...
  }

will work for classes but to test a role, one must use ::does_role directly

=head1 IMPORTED SUBROUTINES

=head2 requires

 requires qw(foo bar);

Declares a list of methods that must be defined to compose role.

=head2 with

 with 'Some::Role1';
 with 'Some::Role2';

Composes another role into the current role.  Only one role may be composed in
at a time to allow the code to remain as simple as possible.

=head2 before

 before foo => sub { ... };

See L<< Class::Method::Modifiers/before method(s) => sub { ... } >> for full
documentation.

=head2 around

 around foo => sub { ... };

See L<< Class::Method::Modifiers/around method(s) => sub { ... } >> for full
documentation.

=head2 after

 after foo => sub { ... };

See L<< Class::Method::Modifiers/after method(s) => sub { ... } >> for full
documentation.

=head1 AUTHORS

See L<Moo> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Moo> for the copyright and license.

=cut
