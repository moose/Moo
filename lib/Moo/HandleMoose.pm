package Moo::HandleMoose;

use strictures 1;
use Moo::_Utils;
use B qw(perlstring);

our %TYPE_MAP;

our $SETUP_DONE;

sub import { return if $SETUP_DONE; inject_all(); $SETUP_DONE = 1; }

sub inject_all {
  require Class::MOP;
  inject_fake_metaclass_for($_)
    for grep $_ ne 'Moo::Object', do { no warnings 'once'; keys %Moo::MAKERS };
  inject_fake_metaclass_for($_) for keys %Moo::Role::INFO;
  require Moose::Meta::Method::Constructor;
  @Moo::HandleMoose::FakeConstructor::ISA = 'Moose::Meta::Method::Constructor';
}

sub maybe_reinject_fake_metaclass_for {
  my ($name) = @_;
  our %DID_INJECT;
  if (delete $DID_INJECT{$name}) {
    unless ($Moo::Role::INFO{$name}) {
      Moo->_constructor_maker_for($name)->install_delayed;
    }
    inject_fake_metaclass_for($name);
  }
}

sub inject_fake_metaclass_for {
  my ($name) = @_;
  require Class::MOP;
  require Moo::HandleMoose::FakeMetaClass;
  Class::MOP::store_metaclass_by_name(
    $name, bless({ name => $name }, 'Moo::HandleMoose::FakeMetaClass')
  );
}

{
  package Moo::HandleMoose::FakeConstructor;

  sub _uninlined_body { \&Moose::Object::new }
}
    

sub inject_real_metaclass_for {
  my ($name) = @_;
  our %DID_INJECT;
  return Class::MOP::get_metaclass_by_name($name) if $DID_INJECT{$name};
  require Moose; require Moo; require Moo::Role;
  Class::MOP::remove_metaclass_by_name($name);
  my ($am_role, $meta, $attr_specs, $attr_order) = do {
    if (my $info = $Moo::Role::INFO{$name}) {
      my @attr_info = @{$info->{attributes}||[]};
      (1, Moose::Meta::Role->initialize($name),
       { @attr_info },
       [ @attr_info[grep !($_ % 2), 0..$#attr_info] ]
      )
    } else {
      my $specs = Moo->_constructor_maker_for($name)->all_attribute_specs;
      (0, Moose::Meta::Class->initialize($name), $specs,
       [ sort { $specs->{$a}{index} <=> $specs->{$b}{index} } keys %$specs ]
      );
    }
  };

  my %methods = %{Role::Tiny->_concrete_methods_of($name)};

  while (my ($meth_name, $meth_code) = each %methods) {
    $meta->add_method($meth_name, $meth_code) if $meth_code;
  }

  # if stuff gets added afterwards, _maybe_reset_handlemoose should
  # trigger the recreation of the metaclass but we need to ensure the
  # Role::Tiny cache is cleared so we don't confuse Moo itself.
  if (my $info = $Role::Tiny::INFO{$name}) {
    delete $info->{methods};
  }

  # needed to ensure the method body is stable and get things named
  Sub::Defer::undefer_sub($_) for grep defined, values %methods;
  my @attrs;
  {
    # This local is completely not required for roles but harmless
    local @{_getstash($name)}{keys %methods};
    my %seen_name;
    foreach my $name (@$attr_order) {
      $seen_name{$name} = 1;
      my %spec = %{$attr_specs->{$name}};
      delete $spec{index};
      $spec{is} = 'ro' if $spec{is} eq 'lazy' or $spec{is} eq 'rwp';
      delete $spec{asserter};
      if (my $isa = $spec{isa}) {
        my $tc = $spec{isa} = do {
          if (my $mapped = $TYPE_MAP{$isa}) {
            $mapped->();
          } else {
            Moose::Meta::TypeConstraint->new(
              constraint => sub { eval { &$isa; 1 } }
            );
          }
        };
        if (my $coerce = $spec{coerce}) {
          $tc->coercion(Moose::Meta::TypeCoercion->new)
             ->_compiled_type_coercion($coerce);
          $spec{coerce} = 1;
        }
      } elsif (my $coerce = $spec{coerce}) {
        my $attr = perlstring($name);
        my $tc = Moose::Meta::TypeConstraint->new(
                   constraint => sub { die "This is not going to work" },
                   inlined => sub {
                      'my $r = $_[42]{'.$attr.'}; $_[42]{'.$attr.'} = 1; $r'
                   },
                 );
        $tc->coercion(Moose::Meta::TypeCoercion->new)
           ->_compiled_type_coercion($coerce);
        $spec{isa} = $tc;
        $spec{coerce} = 1;
      }
      push @attrs, $meta->add_attribute($name => %spec);
    }
    foreach my $mouse (do { our %MOUSE; @{$MOUSE{$name}||[]} }) {
      foreach my $attr ($mouse->get_all_attributes) {
        my %spec = %{$attr};
        delete @spec{qw(
          associated_class associated_methods __METACLASS__
          provides curries
        )};
        my $name = delete $spec{name};
        next if $seen_name{$name}++;
        push @attrs, $meta->add_attribute($name => %spec);
      }
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
    bless(
      $meta->find_method_by_name('new'),
      'Moo::HandleMoose::FakeConstructor',
    );
  }
  $meta->add_role(Class::MOP::class_of($_))
    for grep !/\|/ && $_ ne $name, # reject Foo|Bar and same-role-as-self
      do { no warnings 'once'; keys %{$Role::Tiny::APPLIED_TO{$name}} };
  $DID_INJECT{$name} = 1;
  $meta;
}

1;
