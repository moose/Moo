use strictures 1;
use Test::More;
use Test::Fatal;

BEGIN {
  package MyRole;

  use Role::Tiny;

  requires qw(req1 req2);

  around foo => sub { my $orig = shift; join ' ', 'role foo', $orig->(@_) };

  sub bar { 'role bar' }

  sub baz { 'role baz' }
}

BEGIN {
  package MyClass;

  use constant SIMPLE => 'simple';
  use constant REF_CONST => [ 'ref_const' ];
  use constant VSTRING_CONST => v1;

  sub req1 { }
  sub req2 { }
  sub foo { 'class foo' }
  sub baz { 'class baz' }

}

BEGIN {
  package ExtraClass;
  sub req1 { }
  sub req2 { }
  sub req3 { }
  sub foo { }
  sub baz { 'class baz' }
}

BEGIN {
  package IntermediaryRole;
  use Role::Tiny;
  requires 'req3';
}

BEGIN {
  package NoMethods;

  package OneMethod;

  sub req1 { }
}

sub try_apply_to {
  my $to = shift;
  exception { Role::Tiny->apply_role_to_package($to, 'MyRole') }
}

is(try_apply_to('MyClass'), undef, 'role applies cleanly');
is(MyClass->foo, 'role foo class foo', 'method modifier');
is(MyClass->bar, 'role bar', 'method from role');
is(MyClass->baz, 'class baz', 'method from class');
ok(MyClass->does('MyRole'), 'class does role');
ok(!MyClass->does('Random'), 'class does not do non-role');

like(try_apply_to('NoMethods'), qr/req1, req2/, 'error for both methods');
like(try_apply_to('OneMethod'), qr/req2/, 'error for one method');

is exception {
  Role::Tiny->apply_role_to_package('IntermediaryRole', 'MyRole');
  Role::Tiny->apply_role_to_package('ExtraClass', 'IntermediaryRole');
}, undef, 'No errors applying roles';

ok(ExtraClass->does('MyRole'), 'ExtraClass does MyRole');
ok(ExtraClass->does('IntermediaryRole'), 'ExtraClass does IntermediaryRole');
is(ExtraClass->bar, 'role bar', 'method from role');
is(ExtraClass->baz, 'class baz', 'method from class');

done_testing;

