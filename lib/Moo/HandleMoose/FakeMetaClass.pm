package Moo::HandleMoose::FakeMetaClass;
use Moo::_strictures;

sub DESTROY { }

sub AUTOLOAD {
  my ($meth) = (our $AUTOLOAD =~ /([^:]+)$/);
  my $self = shift;
  die "Can't call $meth without object instance"
    if !ref $self;
  die "Can't inflate Moose metaclass with Moo::sification disabled"
    if $Moo::sification::disabled;
  require Moo::HandleMoose;
  Moo::HandleMoose::inject_real_metaclass_for($self->{name})->$meth(@_)
}
sub can {
  my $self = shift;
  return $self->SUPER::can(@_)
    if !ref $self or $Moo::sification::disabled;
  require Moo::HandleMoose;
  Moo::HandleMoose::inject_real_metaclass_for($self->{name})->can(@_)
}
sub isa {
  my $self = shift;
  return $self->SUPER::isa(@_)
    if !ref $self or $Moo::sification::disabled;
  require Moo::HandleMoose;
  Moo::HandleMoose::inject_real_metaclass_for($self->{name})->isa(@_)
}
sub make_immutable { $_[0] }

1;
