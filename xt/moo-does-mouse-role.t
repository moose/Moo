use strict;
use warnings;

use Test::More "$]" < 5.008009
  ? (skip_all => 'Mouse is broken on perl <= 5.8.8')
  : ();
use Test::Fatal;

BEGIN {
  package Ker;

  use Moo::Role;

  sub has_ker {}
}

BEGIN {
  package Splat2;

  use Mouse::Role;

  requires 'monkey';

  sub punch { 1 }

  sub jab { 0 }

  around monkey => sub { 'OW' };

  has trap => (is => 'ro', default => sub { -1 });

  sub has_splat {}
}

BEGIN {
  package KerSplat2;
  use Moo::Role;

  with qw(Ker Splat2);
}

BEGIN {
  package KerSplattered2;

  use Moo;

  sub monkey { 'WHAT' }

  with qw(KerSplat2);

  sub jab { 3 }
}

BEGIN {
  package Splattered2;

  use Moo;

  sub monkey { 'WHAT' }

  with qw(Splat2);

  sub jab { 3 }
}

BEGIN {
  package Ker::Splattered2;

  use Moo;

  sub monkey { 'WHAT' }

  with qw(Ker Splat2);

  sub jab { 3 }
}

foreach my $s (
    Splattered2->new,
    Ker::Splattered2->new,
    KerSplattered2->new,
) {
  can_ok($s, 'punch')
    and is($s->punch, 1, 'punch');
  can_ok($s, 'jab')
    and is($s->jab, 3, 'jab');
  can_ok($s, 'monkey')
    and is($s->monkey, 'OW', 'monkey');
  can_ok($s, 'trap')
    and is($s->trap, -1, 'trap');
}

foreach my $c (qw/
    Ker::Splattered2
    KerSplattered2
/) {
  can_ok($c, 'has_ker');
  can_ok($c, 'has_splat');
}

is ref Splattered2->meta, 'Moo::HandleMoose::FakeMetaClass',
  'Mouse::Role meta method not copied';

done_testing;
