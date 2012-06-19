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

foreach my $s (
    Splattered->new,
    Splattered2->new,
    Ker::Splattered->new,
    Ker::Splattered2->new,
    KerSplattered->new,
    KerSplattered2->new,
) {
  ok($s->can('punch'))
    and is($s->punch, 1, 'punch');
  ok($s->can('jab'))
    and is($s->jab, 3, 'jab');
  ok($s->can('monkey'))
    and is($s->monkey, 'OW', 'monkey');
  ok($s->can('trap'))
    and is($s->trap, -1, 'trap');
}

foreach my $c (qw/
    Ker::Splattered
    Ker::Splattered2
    KerSplattered
    KerSplattered2
/) {
  ok $c->can('has_ker');
  ok $c->can('has_splat');
}

done_testing;

