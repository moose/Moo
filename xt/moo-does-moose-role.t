use strictures 1;
use Test::More;

BEGIN {
  package Splat;

  use Moose::Role;

  requires 'monkey';

  sub punch { 1 }

  sub jab { 0 }

  around monkey => sub { 'OW' };

  has trap => (is => 'ro', default => sub { -1 });
}

BEGIN {
  package Splat2;

  use Mouse::Role;

  requires 'monkey';

  sub punch { 1 }

  sub jab { 0 }

  around monkey => sub { 'OW' };

  has trap => (is => 'ro', default => sub { -1 });
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

foreach my $s (Splattered->new, Splattered2->new) {
  is($s->punch, 1, 'punch');
  is($s->jab, 3, 'jab');
  is($s->monkey, 'OW', 'monkey');
  is($s->trap, -1, 'trap');
}

done_testing;
