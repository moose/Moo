use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose ();
BEGIN {
  my $sigwarn = $SIG{__WARN__};
  $SIG{__WARN__} = sub {
    die $_[0]
      if $_[0] =~ /Deep recursion/;
    if ($sigwarn) {
      no strict 'refs';
      goto &$sigwarn;
    }
    else {
      warn $_[0];
    }
  };
}

BEGIN {
  package Role1;
  use Moo::Role;
  has attr1 => (is => 'ro', lazy => 1);
}
BEGIN {
  package Class1;
  use Moo;
  with 'Role1';
}
BEGIN {
  package SomeMooseClass;
  use Moose;
  ::like(
    ::exception { with 'Role1' },
    qr/You cannot have a lazy attribute/,
    'reasonable error rather than deep recursion for inflating invalid attr',
  );
}

BEGIN {
  package WTF::Trait;
  use Moose::Role;
  use Moose::Util;
  Moose::Util::meta_attribute_alias('WTF');
  has wtf => (is => 'ro', required => 1);
}

BEGIN {
  package WTF::Class;
  use Moo;
  has ftw => (is => 'ro', traits => [ 'WTF' ]);
}

# avoiding Test::Fatal, because it checks exceptions for truth and that can
# cause more exceptions in this case.  Prefer to trigger stringification
# manually here.

my $e;
eval {
  WTF::Class->meta->get_attribute('ftw');
  1;
} or $e = $@;

$e = "$e";

like(
  $e,
  qr/Attribute \(wtf\) is required/,
  'reasonable error rather than deep recursion for inflating invalid attr (traits)',
);

done_testing;
