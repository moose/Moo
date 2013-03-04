package Moo::Role;

use strictures 1;
use Moo::_Utils;
use base qw(Role::Tiny);

require Moo::sification;

BEGIN { *INFO = \%Role::Tiny::INFO }

our %INFO;

sub _install_tracked {
  my ($target, $name, $code) = @_;
  $INFO{$target}{exports}{$name} = $code;
  _install_coderef "${target}::${name}" => "Moo::Role::${name}" => $code;
}

sub import {
  my $target = caller;
  my ($me) = @_;
  strictures->import;
  if ($Moo::MAKERS{$target} and $Moo::MAKERS{$target}{is_class}) {
    die "Cannot import Moo::Role into a Moo class";
  }
  $INFO{$target} ||= {};
  # get symbol table reference
  my $stash = do { no strict 'refs'; \%{"${target}::"} };
  _install_tracked $target => has => sub {
    my ($name_proto, %spec) = @_;
    my $name_isref = ref $name_proto eq 'ARRAY';
    foreach my $name ($name_isref ? @$name_proto : $name_proto) {
      my $spec_ref = $name_isref ? +{%spec} : \%spec;
      ($INFO{$target}{accessor_maker} ||= do {
        require Method::Generate::Accessor;
        Method::Generate::Accessor->new
      })->generate_method($target, $name, $spec_ref);
      push @{$INFO{$target}{attributes}||=[]}, $name, $spec_ref;
      $me->_maybe_reset_handlemoose($target);
    }
  };
  # install before/after/around subs
  foreach my $type (qw(before after around)) {
    _install_tracked $target => $type => sub {
      require Class::Method::Modifiers;
      push @{$INFO{$target}{modifiers}||=[]}, [ $type => @_ ];
      $me->_maybe_reset_handlemoose($target);
    };
  }
  _install_tracked $target => requires => sub {
    push @{$INFO{$target}{requires}||=[]}, @_;
    $me->_maybe_reset_handlemoose($target);
  };
  _install_tracked $target => with => sub {
    $me->apply_roles_to_package($target, @_);
    $me->_maybe_reset_handlemoose($target);
  };
  return if $INFO{$target}{is_role}; # already exported into this package
  $INFO{$target}{is_role} = 1;
  *{_getglob("${target}::meta")} = $me->can('meta');
  # grab all *non-constant* (stash slot is not a scalarref) subs present
  # in the symbol table and store their refaddrs (no need to forcibly
  # inflate constant subs into real subs) - also add '' to here (this
  # is used later) with a map to the coderefs in case of copying or re-use
  my @not_methods = ('', map { *$_{CODE}||() } grep !ref($_), values %$stash);
  @{$INFO{$target}{not_methods}={}}{@not_methods} = @not_methods;
  # a role does itself
  $Role::Tiny::APPLIED_TO{$target} = { $target => undef };

  if ($INC{'Moo/HandleMoose.pm'}) {
    Moo::HandleMoose::inject_fake_metaclass_for($target);
  }
}

# duplicate from Moo::Object
sub meta {
  require Moo::HandleMoose::FakeMetaClass;
  my $class = ref($_[0])||$_[0];
  bless({ name => $class }, 'Moo::HandleMoose::FakeMetaClass');
}

sub unimport {
  my $target = caller;
  _unimport_coderefs($target, $INFO{$target});
}

sub _maybe_reset_handlemoose {
  my ($class, $target) = @_;
  if ($INC{"Moo/HandleMoose.pm"}) {
    Moo::HandleMoose::maybe_reinject_fake_metaclass_for($target);
  }
}

sub _inhale_if_moose {
  my ($self, $role) = @_;
  _load_module($role);
  my $meta;
  if (!$INFO{$role}
      and (
        $INC{"Moose.pm"}
        and $meta = Class::MOP::class_of($role)
      )
      or (
        Mouse::Util->can('find_meta')
        and $meta = Mouse::Util::find_meta($role)
     )
  ) {
    $INFO{$role}{methods} = {
      map +($_ => $role->can($_)),
        grep !$meta->get_method($_)->isa('Class::MOP::Method::Meta'),
          $meta->get_method_list
    };
    $Role::Tiny::APPLIED_TO{$role} = {
      map +($_->name => 1), $meta->calculate_all_roles
    };
    $INFO{$role}{requires} = [ $meta->get_required_method_list ];
    $INFO{$role}{attributes} = [
      map +($_ => do {
        my $spec = { %{$meta->get_attribute($_)} };

        if ($spec->{isa}) {

          my $get_constraint = do {
            my $pkg = $meta->isa('Mouse::Meta::Role')
                        ? 'Mouse::Util::TypeConstraints'
                        : 'Moose::Util::TypeConstraints';
            _load_module($pkg);
            $pkg->can('find_or_create_isa_type_constraint');
          };

          my $tc = $get_constraint->($spec->{isa});
          my $check = $tc->_compiled_type_constraint;

          $spec->{isa} = sub {
            &$check or die "Type constraint failed for $_[0]"
          };

          if ($spec->{coerce}) {

             # Mouse has _compiled_type_coercion straight on the TC object
             $spec->{coerce} = $tc->${\(
               $tc->can('coercion')||sub { $_[0] }
             )}->_compiled_type_coercion;
          }
        }
        $spec;
      }), $meta->get_attribute_list
    ];
    my $mods = $INFO{$role}{modifiers} = [];
    foreach my $type (qw(before after around)) {
      # Mouse pokes its own internals so we have to fall back to doing
      # the same thing in the absence of the Moose API method
      my $map = $meta->${\(
        $meta->can("get_${type}_method_modifiers_map")
        or sub { shift->{"${type}_method_modifiers"} }
      )};
      foreach my $method (keys %$map) {
        foreach my $mod (@{$map->{$method}}) {
          push @$mods, [ $type => $method => $mod ];
        }
      }
    }
    require Class::Method::Modifiers if @$mods;
    $INFO{$role}{inhaled_from_moose} = 1;
  }
}

sub _maybe_make_accessors {
  my ($self, $role, $target) = @_;
  my $m;
  if ($INFO{$role}{inhaled_from_moose}
      or $INC{"Moo.pm"}
      and $m = Moo->_accessor_maker_for($target)
      and ref($m) ne 'Method::Generate::Accessor') {
    $self->_make_accessors($role, $target);
  }
}

sub _make_accessors_if_moose {
  my ($self, $role, $target) = @_;
  if ($INFO{$role}{inhaled_from_moose}) {
    $self->_make_accessors($role, $target);
  }
}

sub _make_accessors {
  my ($self, $role, $target) = @_;
  my $acc_gen = ($Moo::MAKERS{$target}{accessor} ||= do {
    require Method::Generate::Accessor;
    Method::Generate::Accessor->new
  });
  my $con_gen = $Moo::MAKERS{$target}{constructor};
  my @attrs = @{$INFO{$role}{attributes}||[]};
  while (my ($name, $spec) = splice @attrs, 0, 2) {
    # needed to ensure we got an index for an arrayref based generator
    if ($con_gen) {
      $spec = $con_gen->all_attribute_specs->{$name};
    }
    $acc_gen->generate_method($target, $name, $spec);
  }
}

sub apply_roles_to_package {
  my ($me, $to, @roles) = @_;
  foreach my $role (@roles) {
      $me->_inhale_if_moose($role);
  }
  $me->SUPER::apply_roles_to_package($to, @roles);
}

sub apply_single_role_to_package {
  my ($me, $to, $role) = @_;
  $me->_inhale_if_moose($role);
  $me->_handle_constructor($to, $INFO{$role}{attributes});
  $me->_maybe_make_accessors($role, $to);
  $me->SUPER::apply_single_role_to_package($to, $role);
}

sub create_class_with_roles {
  my ($me, $superclass, @roles) = @_;

  my $new_name = join(
    '__WITH__', $superclass, my $compose_name = join '__AND__', @roles
  );

  return $new_name if $Role::Tiny::COMPOSED{class}{$new_name};

  foreach my $role (@roles) {
      $me->_inhale_if_moose($role);
  }

  my $m;
  if ($INC{"Moo.pm"}
      and $m = Moo->_accessor_maker_for($superclass)
      and ref($m) ne 'Method::Generate::Accessor') {
    # old fashioned way time.
    *{_getglob("${new_name}::ISA")} = [ $superclass ];
    $me->apply_roles_to_package($new_name, @roles);
    return $new_name;
  }

  require Sub::Quote;

  $me->SUPER::create_class_with_roles($superclass, @roles);

  foreach my $role (@roles) {
    die "${role} is not a Role::Tiny" unless my $info = $INFO{$role};
  }

  $Moo::MAKERS{$new_name} = {};

  $me->_handle_constructor(
    $new_name, [ map @{$INFO{$_}{attributes}||[]}, @roles ], $superclass
  );

  return $new_name;
}

sub _composable_package_for {
  my ($self, $role) = @_;
  my $composed_name = 'Role::Tiny::_COMPOSABLE::'.$role;
  return $composed_name if $Role::Tiny::COMPOSED{role}{$composed_name};
  $self->_make_accessors_if_moose($role, $composed_name);
  $self->SUPER::_composable_package_for($role);
}

sub _install_single_modifier {
  my ($me, @args) = @_;
  _install_modifier(@args);
}

sub _handle_constructor {
  my ($me, $to, $attr_info, $superclass) = @_;
  return unless $attr_info && @$attr_info;
  if ($INFO{$to}) {
    push @{$INFO{$to}{attributes}||=[]}, @$attr_info;
  } else {
    # only fiddle with the constructor if the target is a Moo class
    if ($INC{"Moo.pm"}
        and my $con = Moo->_constructor_maker_for($to, $superclass)) {
      # shallow copy of the specs since the constructor will assign an index
      $con->register_attribute_specs(map ref() ? { %$_ } : $_, @$attr_info);
    }
  }
}

1;

=head1 NAME

Moo::Role - Minimal Object Orientation support for Roles

=head1 SYNOPSIS

 package My::Role;

 use Moo::Role;

 sub foo { ... }

 sub bar { ... }

 has baz => (
   is => 'ro',
 );

 1;

And elsewhere:

 package Some::Class;

 use Moo;

 # bar gets imported, but not foo
 with('My::Role');

 sub foo { ... }

 1;

=head1 DESCRIPTION

C<Moo::Role> builds upon L<Role::Tiny>, so look there for most of the
documentation on how this works.  The main addition here is extra bits to make
the roles more "Moosey;" which is to say, it adds L</has>.

=head1 IMPORTED SUBROUTINES

See L<Role::Tiny/IMPORTED SUBROUTINES> for all the other subroutines that are
imported by this module.

=head2 has

 has attr => (
   is => 'ro',
 );

Declares an attribute for the class to be composed into.  See
L<Moo/has> for all options.

=head1 SUPPORT

See L<Moo> for support and contact informations.

=head1 AUTHORS

See L<Moo> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Moo> for the copyright and license.
