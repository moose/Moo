package Moo::HandleMoose::_TypeMap;
use strictures 1;

package
  Moo::HandleMoose;
our %TYPE_MAP;

package Moo::HandleMoose::_TypeMap;

use Scalar::Util ();
use Tie::Hash ();

our @ISA = qw(Tie::StdHash);

our %WEAK_TYPES;

sub _str_to_ref {
  my $in = shift;
  return $in
    if ref $in;

  if ($in =~ /(?:^|=)[A-Z]+\(0x([0-9a-zA-Z]+)\)$/) {
    my $id = do { no warnings 'portable'; hex "$1" };
    require B;
    my $sv = bless \$id, 'B::SV';
    my $ref = eval { $sv->object_2svref };
    if (!defined $ref) {
      die <<'END_ERROR';
Moo initialization encountered types defined in a parent thread - ensure that
Moo is require()d before any further thread spawns following a type definition.
END_ERROR
    }
    return $ref;
  }
  return $in;
}

sub STORE {
  my ($self, $key, $value) = @_;
  my $type = _str_to_ref($key);
  $WEAK_TYPES{$type} = $type;
  Scalar::Util::weaken($WEAK_TYPES{$type})
    if ref $type;
  $self->SUPER::STORE($key, $value);
}

sub CLONE {
  my @types = map {
    defined $WEAK_TYPES{$_} ? ($WEAK_TYPES{$_} => $TYPE_MAP{$_}) : ()
  } keys %TYPE_MAP;
  %WEAK_TYPES = ();
  %TYPE_MAP = @types;
}

sub DESTROY {
  my %types = %{$_[0]};
  untie %TYPE_MAP;
  %TYPE_MAP = %types;
}

my @types = %TYPE_MAP;
tie %TYPE_MAP, __PACKAGE__;
%TYPE_MAP = @types;

1;
