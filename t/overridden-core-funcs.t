use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
  package AddOverrides;
  $INC{"AddOverrides.pm"} = __FILE__;
  use Carp ();
  sub import {
    my $package = caller;
    for my $sub (
      'defined',
      'join',
      'ref',
      'die',
      'shift',
      'sort',
      'undef',
    ) {
      my $proto = prototype "CORE::$sub";
      no strict 'refs';
      *{"${package}::$sub"} = \&{"${package}::$sub"};
      eval "sub ${package}::$sub ".($proto ? "($proto)" : '') . ' { Carp::confess("local '.$sub.'") }; 1'
        or die $@;
    }
  }
}

{
  package Foo;
  use Moo;
  sub welp { 1 }
}

{
  package WithOverridden;
  use AddOverrides;
  use Moo;

  sub BUILD { 1 }
  sub DEMOLISH { CORE::die "demolish\n" if $::FATAL_DEMOLISH }
  around BUILDARGS => sub {
    my $orig = CORE::shift();
    my $self = CORE::shift();
    $self->$orig(@_);
  };

  has attr1 => (is => 'ro', required => 1, handles => ['welp']);
  has attr2 => (is => 'ro', default => CORE::undef());
  has attr3 => (is => 'rw', isa => sub { CORE::die "nope" } );
}

unlike exception { WithOverridden->new(1) }, qr/local/,
  'bad constructor arguments error ignores local functions';
unlike exception { WithOverridden->new }, qr/local/,
  'missing attributes error ignores local functions';
unlike exception { WithOverridden->new(attr1 => 1, attr3 => 1) }, qr/local/,
  'constructor isa checks ignores local functions';
my $o;
is exception { $o = WithOverridden->new(attr1 => Foo->new) }, undef,
  'constructor without error ignores local functions';
unlike exception { $o->attr3(1) }, qr/local/,
  'isa checks ignores local functions';
is exception { $o->welp }, undef,
  'delegates ignores local functions';

{
  no warnings FATAL => 'all';
  use warnings 'all';
  my $w = '';
  local $SIG{__WARN__} = sub { $w .= $_[0] };
  local $::FATAL_DEMOLISH = 1;
  undef $o;
  unlike $w, qr/local/,
    'destroy ignores local functions';
}

done_testing;
