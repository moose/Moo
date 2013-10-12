package Moo::_Utils;

no warnings 'once'; # guard against -w

sub _getglob { \*{$_[0]} }
sub _getstash { \%{"$_[0]::"} }

use constant lt_5_8_3 => ( $] < 5.008003 or $ENV{MOO_TEST_PRE_583} ) ? 1 : 0;
use constant can_haz_subname => eval { require Sub::Name };

use strictures 1;
use Module::Runtime qw(use_package_optimistically module_notional_filename);

use Devel::GlobalDestruction ();
use base qw(Exporter);
use Moo::_mro;

our @EXPORT = qw(
    _getglob _install_modifier _load_module _maybe_load_module
    _get_linear_isa _getstash _install_coderef _name_coderef
    _unimport_coderefs _in_global_destruction _set_loaded
);

sub _in_global_destruction ();
*_in_global_destruction = \&Devel::GlobalDestruction::in_global_destruction;

sub _install_modifier {
  my ($into, $type, $name, $code) = @_;

  if (my $to_modify = $into->can($name)) { # CMM will throw for us if not
    require Sub::Defer;
    Sub::Defer::undefer_sub($to_modify);
  }

  Class::Method::Modifiers::install_modifier(@_);
}

our %MAYBE_LOADED;

sub _load_module {
  my $module = $_[0];
  my $file = module_notional_filename($module);
  use_package_optimistically($module);
  return 1
    if $INC{$file};
  my $error = $@ || "Can't locate $file";

  # can't just ->can('can') because a sub-package Foo::Bar::Baz
  # creates a 'Baz::' key in Foo::Bar's symbol table
  my $stash = _getstash($module)||{};
  return 1 if grep +(!ref($_) and *$_{CODE}), values %$stash;
  return 1
    if $INC{"Moose.pm"} && Class::MOP::class_of($module)
    or Mouse::Util->can('find_meta') && Mouse::Util::find_meta($module);
  die $error;
}

sub _maybe_load_module {
  return $MAYBE_LOADED{$_[0]} if exists $MAYBE_LOADED{$_[0]};
  (my $proto = $_[0]) =~ s/::/\//g;
  local $@;
  if (eval { require "${proto}.pm"; 1 }) {
    $MAYBE_LOADED{$_[0]} = 1;
  } else {
    if (exists $INC{"${proto}.pm"}) {
      warn "$_[0] exists but failed to load with error: $@";
    }
    $MAYBE_LOADED{$_[0]} = 0;
  }
  return $MAYBE_LOADED{$_[0]};
}

sub _set_loaded {
  $INC{Module::Runtime::module_notional_filename($_[0])} ||= $_[1];
}

sub _get_linear_isa {
  return mro::get_linear_isa($_[0]);
}

sub _install_coderef {
  no warnings 'redefine';
  *{_getglob($_[0])} = _name_coderef(@_);
}

sub _name_coderef {
  shift if @_ > 2; # three args is (target, name, sub)
  can_haz_subname ? Sub::Name::subname(@_) : $_[1];
}

sub _unimport_coderefs {
  my ($target, $info) = @_;
  return unless $info and my $exports = $info->{exports};
  my %rev = reverse %$exports;
  my $stash = _getstash($target);
  foreach my $name (keys %$exports) {
    if ($stash->{$name} and defined(&{$stash->{$name}})) {
      if ($rev{$target->can($name)}) {
        my $old = delete $stash->{$name};
        my $full_name = join('::',$target,$name);
        # Copy everything except the code slot back into place (e.g. $has)
        foreach my $type (qw(SCALAR HASH ARRAY IO)) {
          next unless defined(*{$old}{$type});
          no strict 'refs';
          *$full_name = *{$old}{$type};
        }
      }
    }
  }
}

my $type_map = \%Moo::HandleMoose::TYPE_MAP;
my $weak_types = \%Moo::HandleMoose::WEAK_TYPES;

my %old_map = %$type_map;

{
  package
    Moo::HandleMoose::TypeMap;
  use Tie::Hash;
  use Scalar::Util qw(weaken);
  our @ISA = qw(Tie::StdHash);
  sub STORE {
    weaken($weak_types->{$_[1]} = $_[1]);
    $_[0]->SUPER::STORE(@_[1..$#_]);
  }

  sub CLONE {
    %$type_map   = map {
      defined $weak_types->{$_} ? ($weak_types->{$_} => $type_map->{$_}) : ()
    } keys %$type_map;
    %$weak_types = map {
      defined $weak_types->{$_} ? ($weak_types->{$_} => $weak_types->{$_}) : ()
    } keys %$weak_types;
    weaken $_ for values %$weak_types;
  }

  tie %$type_map, __PACKAGE__;
}

if (keys %old_map) {
  require B;
  for my $key (keys %old_map) {
    my $old_value = $old_map{$key};
    if ($key =~ /(?:^|=)[A-Z]+\(0x([0-9a-zA-Z]+)\)$/) {
      my $id = do { no warnings; hex "$1" };
      my $sv = bless \$id, 'B::SV';
      my $ref = eval { $sv->object_2svref };
      if (!defined $ref) {
        die "make sure Moo is loaded before creating threads if types are defined before creating threads";
      }
      $key = $ref;
    }
    $type_map->{$key} = $old_value;
  }
}

1;
