use strict;
use warnings;

use Test::More;
use Test::Fatal;
use File::Basename qw(dirname);

BEGIN {
  package Foo;
  use Moo;

  sub DEMOLISH {
    my $self = shift;
    my ($igd) = @_;
    ::ok !$igd,
      'in_global_destruction state is passed to DEMOLISH properly (false)';
  }
}

{
  my $foo = Foo->new;
}

delete $ENV{PERL5LIB};
delete $ENV{PERL5OPT};
my $out = system $^X, (map "-I$_", @INC), dirname(__FILE__).'/global-destruction-helper.pl', 219;
is $out >> 8, 219,
  'in_global_destruction state is passed to DEMOLISH properly (false)';

done_testing;
