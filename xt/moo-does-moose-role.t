use strictures 1;
use Test::More;
use Test::Fatal;

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

is ref Splattered2->meta, 'Moo::HandleMoose::FakeMetaClass',
  'Mouse::Role meta method not copied';

{
  package MooseAttrTrait;
  use Moose::Role;

  has 'extra_attr' => (is => 'ro');
  has 'extra_attr_noinit' => (is => 'ro', init_arg => undef);
}

{
  local $SIG{__WARN__} = sub { fail "warning: $_[0]" };
  package UsingMooseTrait;
  use Moo;

  has one => (
    is => 'ro',
    traits => ['MooseAttrTrait'],
    extra_attr => 'one',
    extra_attr_noinit => 'two',
  );
}

ok( UsingMooseTrait->meta
      ->find_attribute_by_name('one')->can('extra_attr'),
    'trait was properly applied');
is( UsingMooseTrait->meta->find_attribute_by_name('one')
      ->extra_attr,
    'one',
    'trait attributes maintain values');

{
  package NeedTrap;
  use Moo::Role;

  requires 'trap';
}

is exception {
  package Splattrap;
  use Moo;
  sub monkey {}

  with qw(Splat NeedTrap);
}, undef, 'requires satisfied by Moose attribute composed at the same time';

{
  package HasMonkey;
  use Moo;
  sub monkey {}
}
is exception {
  Moo::Role->create_class_with_roles('HasMonkey', 'Splat', 'NeedTrap');
}, undef, ' ... and when created by create_class_with_roles';

done_testing;
