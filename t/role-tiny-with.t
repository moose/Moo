use strictures 1;
use Test::More;

BEGIN {
  package MyRole;

  use Role::Tiny;

  sub bar { 'role bar' }

  sub baz { 'role baz' }
}

BEGIN {
  package MyClass;

  use Role::Tiny::With;

  with 'MyRole';

  sub foo { 'class foo' }

  sub baz { 'class baz' }

}

is(MyClass->foo, 'class foo', 'method from class no override');
is(MyClass->bar, 'role bar',  'method from role');
is(MyClass->baz, 'class baz', 'method from class');

done_testing;
