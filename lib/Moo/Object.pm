package Moo::Object;

use strictures 1;

our %NO_BUILD;
our $BUILD_MAKER;

sub new {
  my $class = shift;
  $NO_BUILD{$class} and
    return bless({ ref($_[0]) eq 'HASH' ? %{$_[0]} : @_ }, $class);
  $NO_BUILD{$class} = !$class->can('BUILD') unless exists $NO_BUILD{$class};
  $NO_BUILD{$class}
    ? bless({ ref($_[0]) eq 'HASH' ? %{$_[0]} : @_ }, $class)
    : do {
        my $proto = ref($_[0]) eq 'HASH' ? $_[0] : { @_ };
        bless({ %$proto }, $class)->BUILDALL($proto);
      };
}

sub BUILDALL {
  my $self = shift;
  $self->${\(($BUILD_MAKER ||= do {
    require Method::Generate::BuildAll;
    Method::Generate::BuildAll->new
  })->generate_method(ref($self)))}(@_);
}

sub does {
  require Role::Tiny;
  { no warnings 'redefine'; *does = \&Role::Tiny::does_role }
  goto &Role::Tiny::does_role;
}

1;
