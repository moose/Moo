use strictures 1;
use Test::More qw(no_plan);
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

  sub req1 { }
  sub req2 { }
  sub foo { 'class foo' }
  sub baz { 'class baz' }

}

BEGIN {
  package NoMethods;

  package OneMethod;

  sub req1 { }
}

sub try_apply_to {
  my $to = shift;
  exception { Role::Tiny->apply_role_to_package('MyRole', $to) }
}

is(try_apply_to('MyClass'), undef, 'role applies cleanly');
is(MyClass->foo, 'role foo class foo', 'method modifier');
is(MyClass->bar, 'role bar', 'method from role');
is(MyClass->baz, 'class baz', 'method from class');

like(try_apply_to('NoMethods'), qr/req1, req2/, 'error for both methods');
like(try_apply_to('OneMethod'), qr/req2/, 'error for one method');
