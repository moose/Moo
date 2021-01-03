use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
  package Foo;
  use Moo;
  sub DEMOLISH {
    die "Error in DEMOLISH";
  }
}
my @warnings;
my @looped_exceptions;
my $o = Foo->new;

{
  local $SIG{__WARN__} = sub {
    push @warnings, $_[0];
  };

  # make sure we don't loop infinitely
  my $last_die;
  local $SIG{__DIE__} = sub {
    my $location = join(':', caller);
    if ($last_die && $last_die eq $location) {
      push @looped_exceptions, $_[0];
      die @_;
    }
    $last_die = $location;
  };

  {
    no warnings FATAL => 'misc';
    use warnings 'misc';
    undef $o;
    # if undef is the last statement in a block, its effect is delayed until
    # after the block is cleaned up (and our warning settings won't be applied)
    1;
  }
}

like $warnings[0], qr/\(in cleanup\) Error in DEMOLISH/,
  'error in DEMOLISH converted to warning';
is scalar @warnings, 1,
  'no other warnings generated';
is scalar @looped_exceptions, 0,
  'no infinitely looping exception in DESTROY';

done_testing;
