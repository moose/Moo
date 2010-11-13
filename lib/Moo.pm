package Moo;

use strictures 1;
use Moo::_Utils;

our $VERSION = '0.009001'; # 0.9.1
$VERSION = eval $VERSION;

our %MAKERS;

sub import {
  my $target = caller;
  my $class = shift;
  strictures->import;
  *{_getglob("${target}::extends")} = sub {
    _load_module($_) for @_;
    *{_getglob("${target}::ISA")} = \@_;
  };
  *{_getglob("${target}::with")} = sub {
    require Moo::Role;
    die "Only one role supported at a time by with" if @_ > 1;
    Moo::Role->apply_role_to_package($_[0], $target);
  };
  $MAKERS{$target} = {};
  *{_getglob("${target}::has")} = sub {
    my ($name, %spec) = @_;
    ($MAKERS{$target}{accessor} ||= do {
      require Method::Generate::Accessor;
      Method::Generate::Accessor->new
    })->generate_method($target, $name, \%spec);
    $class->_constructor_maker_for($target)
          ->register_attribute_specs($name, \%spec);
  };
  foreach my $type (qw(before after around)) {
    *{_getglob "${target}::${type}"} = sub {
      _install_modifier($target, $type, @_);
    };
  }
  {
    no strict 'refs';
    @{"${target}::ISA"} = do {
      require Moo::Object; ('Moo::Object');
    } unless @{"${target}::ISA"};
  }
}

sub _constructor_maker_for {
  my ($class, $target) = @_;
  return unless $MAKERS{$target};
  $MAKERS{$target}{constructor} ||= do {
    require Method::Generate::Constructor;
    Method::Generate::Constructor
      ->new(
        package => $target,
        accessor_generator => do {
          require Method::Generate::Accessor;
          Method::Generate::Accessor->new;
        }
      )
      ->install_delayed
      ->register_attribute_specs(do {
        my @spec;
        # using the -last- entry in @ISA means that classes created by
        # Role::Tiny as N roles + superclass will still get the attributes
        # from the superclass
        if (my $super = do { no strict 'refs'; ${"${target}::ISA"}[-1] }) {
          if (my $con = $MAKERS{$super}{constructor}) {
            @spec = %{$con->all_attribute_specs};
          }
        }
        @spec;
      });
  }
}

1;
