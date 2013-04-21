use strictures 1;
use Test::More;

BEGIN {
  package Ker;

  use Moo::Role;

  sub has_ker {}
}

BEGIN {
  package Splat;

  use Moose::Role;

  requires 'monkey';

  sub punch { 1 }

  sub jab { 0 }

  around monkey => sub { 'OW' };

  has trap => (is => 'ro', default => sub { -1 });

  sub has_splat {}
}

BEGIN {
    package KerSplat;
    use Moo::Role;

    with qw/
        Ker
        Splat
    /;
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

    with qw/
        Ker
        Splat2
    /;
}

BEGIN {
  package Splattered;

  use Moo;

  sub monkey { 'WHAT' }

  with 'Splat';

  sub jab { 3 }
}

BEGIN {
  package Splattered2;

  use Moo;

  sub monkey { 'WHAT' }

  with 'Splat2';

  sub jab { 3 }
}

BEGIN {
  package Ker::Splattered;

  use Moo;

  sub monkey { 'WHAT' }

  with qw/ Ker Splat /;

  sub jab { 3 }
}

BEGIN {
  package Ker::Splattered2;

  use Moo;

  sub monkey { 'WHAT' }

  with qw/ Ker Splat2 /;

  sub jab { 3 }
}

BEGIN {
  package KerSplattered;

  use Moo;

  sub monkey { 'WHAT' }

  with qw/ KerSplat /;

  sub jab { 3 }
}

BEGIN {
  package KerSplattered2;

  use Moo;

  sub monkey { 'WHAT' }

  with qw/ KerSplat2 /;

  sub jab { 3 }
}

BEGIN {
  package Plunk;

  use Moo::Role;

  has pp => (is => 'rw', moosify => sub {
    my $spec = shift;
    $spec->{documentation} = 'moosify';
  });
}

BEGIN {
  package Plank;

  use Moo;
  use Sub::Quote;

  has vv => (is => 'rw', moosify => [quote_sub(q|
    $_[0]->{documentation} = 'moosify';
  |), sub { $_[0]->{documentation} = $_[0]->{documentation}.' foo'; }]);
}

BEGIN {
  package Plunker;

  use Moose;

  with 'Plunk';
}

BEGIN {
  package Planker;

  use Moose;

  extends 'Plank';
}

BEGIN {
  package Plonk;
  use Moo;
  has kk => (is => 'rw', moosify => [sub {
    $_[0]->{documentation} = 'parent';
  }]);
}
BEGIN {
  package Plonker;
  use Moo;
  extends 'Plonk';
  has '+kk' => (moosify => sub {
    my $spec = shift;
    $spec->{documentation} .= 'child';
  });
}
BEGIN{
  local $SIG{__WARN__} = sub { fail "warning: $_[0]" };
  package SplatteredMoose;
  use Moose;
  extends 'Splattered';
}

foreach my $s (
    Splattered->new,
    Splattered2->new,
    Ker::Splattered->new,
    Ker::Splattered2->new,
    KerSplattered->new,
    KerSplattered2->new,
    SplatteredMoose->new
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
    Ker::Splattered
    Ker::Splattered2
    KerSplattered
    KerSplattered2
/) {
  can_ok($c, 'has_ker');
  can_ok($c, 'has_splat');
}

is(Plunker->meta->find_attribute_by_name('pp')->documentation, 'moosify', 'moosify modifies attr specs');
is(Planker->meta->find_attribute_by_name('vv')->documentation, 'moosify foo', 'moosify modifies attr specs as array');

is( Plonker->meta->find_attribute_by_name('kk')->documentation,
    'parentchild',
    'moosify applies for overridden attributes with roles');

done_testing;
