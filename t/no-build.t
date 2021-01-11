use strict;
use warnings;

use Test::More;
use Moo::_Utils ();

BEGIN {
  package Class::Diminutive;

  sub new {
    my $class = shift;
    my $args = $class->BUILDARGS(@_);
    my $no_build = delete $args->{__no_BUILD__};
    my $self = bless { %$args }, $class;
    $self->BUILDALL
      unless $no_build;
    return $self;
  }
  sub BUILDARGS {
    my $class = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    return \%args;
  }
  sub BUILDALL {
    my $self = shift;
    my $class = ref $self;
    my @builds =
      grep { defined }
      map {; no strict 'refs'; *{$_.'::BUILD'}{CODE} }
      @{Moo::_Utils::_linear_isa($class)};
    for my $build (@builds) {
      $self->$build;
    }
  }
}

BEGIN {
  package TestClass1;

  our @ISA = ('Class::Diminutive');
  sub BUILD {
    $_[0]->{build_called}++;
  }
  sub BUILDARGS {
    my $class = shift;
    my $args = $class->SUPER::BUILDARGS(@_);
    $args->{no_build_used} = $args->{__no_BUILD__};
    return $args;
  }
}

my $o = TestClass1->new;
is $o->{build_called}, 1, 'mini class builder working';

BEGIN {
  package TestClass2;
  use Moo;
  extends 'TestClass1';
}

my $o2 = TestClass2->new;
is $o2->{build_called}, 1, 'BUILD still called when extending mini class builder';
is $o2->{no_build_used}, 1, '__no_BUILD__ was passed to mini builder';

my $o3 = TestClass2->new({__no_BUILD__ => 1});
is $o3->{build_called}, undef, '__no_BUILD__ inhibits Moo calling BUILD';

done_testing;
