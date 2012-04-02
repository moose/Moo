package Moo::HandleMoose;

use strictures 1;
use Moo::_Utils;

sub import { inject_all() }

sub inject_all {
  require Class::MOP;
  inject_fake_metaclass_for($_) for grep $_ ne 'Moo::Object', keys %Moo::MAKERS;
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
  my ($meta, $attr_specs) = do {
    if (my $info = $Moo::Role::INFO{$name}) {
      (Moose::Meta::Role->initialize($name), $info->{attributes})
    } else {
      my $specs = Moo->_constructor_maker_for($name)->all_attribute_specs;
      (Moose::Meta::Class->initialize($name), $specs);
    }
  };
  my %methods = %{Role::Tiny->_concrete_methods_of($name)};
  my @attrs;
  {
    local @{_getstash($name)}{keys %methods};
    foreach my $name (keys %$attr_specs) {
      push @attrs, $meta->add_attribute($name => %{$attr_specs->{$name}});
    }
  }
  foreach my $attr (@attrs) {
    foreach my $method (@{$attr->associated_methods}) {
      $method->{body} = $name->can($method->name);
    }
  }
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
