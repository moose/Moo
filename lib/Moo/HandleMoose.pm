package Moo::HandleMoose;

use strictures 1;
use Moo::_Utils;

our %TYPE_MAP;

our $SETUP_DONE;

sub import { return if $SETUP_DONE; inject_all(); $SETUP_DONE = 1; }

sub inject_all {
  require Class::MOP;
  inject_fake_metaclass_for($_) for grep $_ ne 'Moo::Object', keys %Moo::MAKERS;
  inject_fake_metaclass_for($_) for keys %Moo::Role::INFO;
}

sub inject_fake_metaclass_for {
  my ($name) = @_;
  require Class::MOP;
  Class::MOP::store_metaclass_by_name(
    $name, bless({ name => $name }, 'Moo::HandleMoose::FakeMetaClass')
  );
}

our %DID_INJECT;

sub inject_real_metaclass_for {
  my ($name) = @_;
  return Class::MOP::get_metaclass_by_name($name) if $DID_INJECT{$name};
  require Moose; require Moo; require Moo::Role;
  Class::MOP::remove_metaclass_by_name($name);
  my ($am_role, $meta, $attr_specs) = do {
    if (my $info = $Moo::Role::INFO{$name}) {
      (1, Moose::Meta::Role->initialize($name), $info->{attributes})
    } else {
      my $specs = Moo->_constructor_maker_for($name)->all_attribute_specs;
      (0, Moose::Meta::Class->initialize($name), $specs);
    }
  };
  my %methods = %{Role::Tiny->_concrete_methods_of($name)};
  my @attrs;
  {
    # This local is completely not required for roles but harmless
    local @{_getstash($name)}{keys %methods};
    foreach my $name (keys %$attr_specs) {
      my %spec = %{$attr_specs->{$name}};
      $spec{is} = 'ro' if $spec{is} eq 'lazy' or $spec{is} eq 'rwp';
      delete $spec{asserter};
      if (my $isa = $spec{isa}) {
        $spec{isa} = do {
          if (my $mapped = $TYPE_MAP{$isa}) {
            $mapped->();
          } else {
            Moose::Meta::TypeConstraint->new(
              constraint => sub { eval { &$isa; 1 } }
            );
          }
        };
      }
      push @attrs, $meta->add_attribute($name => %spec);
    }
  }
  if ($am_role) {
    my $info = $Moo::Role::INFO{$name};
    $meta->add_required_methods(@{$info->{requires}});
    foreach my $modifier (@{$info->{modifiers}}) {
      my ($type, @args) = @$modifier;
      $meta->${\"add_${type}_method_modifier"}(@args);
    }
  } else {
    foreach my $attr (@attrs) {
      foreach my $method (@{$attr->associated_methods}) {
        $method->{body} = $name->can($method->name);
      }
    }
  }
  $meta->add_role(Class::MOP::class_of($_))
    for keys %{$Role::Tiny::APPLIED_TO{$name}};
  $DID_INJECT{$name} = 1;
  $meta;
}

{
  package Moo::HandleMoose::FakeMetaClass;

  sub DESTROY { }

  sub AUTOLOAD {
    my ($meth) = (our $AUTOLOAD =~ /([^:]+)$/);
    Moo::HandleMoose::inject_real_metaclass_for((shift)->{name})->$meth(@_)
  }
  sub can {
    Moo::HandleMoose::inject_real_metaclass_for((shift)->{name})->can(@_)
  }
  sub isa {
    Moo::HandleMoose::inject_real_metaclass_for((shift)->{name})->isa(@_)
  }
}

1;
