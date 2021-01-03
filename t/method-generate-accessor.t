use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Method::Generate::Accessor;
use Sub::Quote 'quote_sub';
use Sub::Defer ();

my $gen;
BEGIN {
  $gen = Method::Generate::Accessor->new;
}

{
  package Foo;
  use Moo;
}

BEGIN {
  # lie about overload.pm just in case
  local $INC{'overload.pm'};
  delete $INC{'overload.pm'};
  my $c = bless {}, 'Gorf';
  like(
    exception { $gen->generate_method('Foo' => 'gorf' => { is => 'ro', coerce => $c } ) },
    qr/^Invalid coerce '\Q$c\E' for Foo->gorf /, "coerce - object rejected (before overload loaded)"
  );
}

{
  package WithOverload;
  use overload '&{}' => sub { sub { 5 } }, fallback => 1;
  sub new { bless {} }
}

$gen->generate_method('Foo' => 'one' => { is => 'ro' });

$gen->generate_method('Foo' => 'two' => { is => 'rw' });

like(
  exception { $gen->generate_method('Foo' => 'three' => {}) },
  qr/Must have an is/, 'No is rejected'
);

like(
  exception { $gen->generate_method('Foo' => 'three' => { is => 'purple' }) },
  qr/Unknown is purple/, 'is purple rejected'
);

is(exception {
  $gen->generate_method('Foo' => 'three' => { is => 'bare', predicate => 1 });
}, undef, 'generating bare accessor works');

ok(Foo->can('has_three'), 'bare accessor will still generate predicate');

like(
  exception { $gen->generate_method('Foo' => 'four' => { is => 'ro', coerce => 5 }) },
  qr/Invalid coerce/, "coerce - scalar rejected"
);

is(
  exception { $gen->generate_method('Foo' => 'four' => { is => 'ro', default => 5 }) },
  undef, "default - non-ref scalar accepted"
);

foreach my $setting (qw( default coerce )) {

  like(
    exception { $gen->generate_method('Foo' => 'five' => { allow_overwrite => 1, is => 'ro', $setting => [] }) },
    qr/Invalid $setting/, "$setting - arrayref rejected"
  );

  like(
    exception { $gen->generate_method('Foo' => 'five' => { allow_overwrite => 1, is => 'ro', $setting => Foo->new }) },
    qr/Invalid $setting/, "$setting - non-code-convertible object rejected"
  );

  is(
    exception { $gen->generate_method('Foo' => 'six' => { allow_overwrite => 1, is => 'ro', $setting => sub { 5 } }) },
    undef, "$setting - coderef accepted"
  );

  is(
    exception { $gen->generate_method('Foo' => 'seven' => { allow_overwrite => 1, is => 'ro', $setting => bless sub { 5 } => 'Blah' }) },
    undef, "$setting - blessed sub accepted"
  );

  is(
    exception { $gen->generate_method('Foo' => 'eight' => { allow_overwrite => 1, is => 'ro', $setting => WithOverload->new }) },
    undef, "$setting - object with overloaded ->() accepted"
  );

  like(
    exception { $gen->generate_method('Foo' => 'nine' => { allow_overwrite => 1, is => 'ro', $setting => bless {} => 'Blah' }) },
    qr/Invalid $setting/, "$setting - object rejected"
  );
}

is(
  exception { $gen->generate_method('Foo' => 'ten' => { is => 'ro', builder => '_build_ten' }) },
  undef, 'builder - string accepted',
);

is(
  exception { $gen->generate_method('Foo' => 'eleven' => { is => 'ro', builder => sub {} }) },
  undef, 'builder - coderef accepted'
);

like(
  exception { $gen->generate_method('Foo' => 'twelve' => { is => 'ro', builder => 'build:twelve' }) },
  qr/Invalid builder/, 'builder - invalid name rejected',
);

is(
  exception { $gen->generate_method('Foo' => 'thirteen' => { is => 'ro', builder => 'build::thirteen' }) },
  undef, 'builder - fully-qualified name accepted',
);

is(
  exception { $gen->generate_method('Foo' => 'fifteen' => { is => 'lazy', builder => sub {15} }) },
  undef, 'builder - coderef accepted'
);

is(
  exception { $gen->generate_method('Foo' => 'sixteen' => { is => 'lazy', builder => quote_sub q{ 16 } }) },
  undef, 'builder - quote_sub accepted'
);

{
  my $methods = $gen->generate_method('Foo' => 'seventeen' => { is => 'lazy', default => 0 }, { no_defer => 0 });
  ok Sub::Defer::defer_info($methods->{seventeen}), 'quote opts are passed on';
}

ok !$gen->is_simple_attribute('attr', { builder => 'build_attr' }),
  "attribute with builder isn't simple";
ok $gen->is_simple_attribute('attr', { clearer => 'clear_attr' }),
  "attribute with clearer is simple";

{
  my ($code, $cap) = $gen->generate_get_default('$self', 'attr',
    { default => 5 });
  is eval $code, 5, 'non-ref default code works';
  is_deeply $cap, {}, 'non-ref default has no captures';
}

{
  my ($code, $cap) = $gen->generate_simple_get('$self', 'attr',
    { default => 1 });
  my $self = { attr => 5 };
  is eval $code, 5, 'simple get code works';
  is_deeply $cap, {}, 'simple get code has no captures';
}

{
  my ($code, $cap) = $gen->generate_coerce('attr', '$value',
    quote_sub q{ $_[0] + 1 });
  my $value = 5;
  is eval $code, 6, 'coerce from quoted sub code works';
  is_deeply $cap, {}, 'coerce from quoted sub has no captures';
}

{
  my ($code, $cap) = $gen->generate_trigger('attr', '$self', '$value',
    quote_sub q{ $_[0]{trigger} = $_[1] });
  my $self = {};
  my $value = 5;
  eval $code;
  is $self->{trigger}, 5, 'trigger from quoted sub code works';
  is_deeply $cap, {}, 'trigger from quoted sub has no captures';
}

{
  my ($code, $cap) = $gen->generate_isa_check('attr', '$value',
    quote_sub q{ die "bad value: $_[0]" unless $_[0] && $_[0] == 5 });
  my $value = 4;
  eval $code;
  like $@, qr/bad value: 4/, 'isa from quoted sub code works';
  is_deeply $cap, {}, 'isa from quoted sub has no captures';
}

{
  my ($code, $cap) = $gen->generate_populate_set(
    '$obj', 'attr', { is => 'ro' }, undef, undef, 'attr',
  );
  is $code, '', 'populate without eager default or test is blank';
  is_deeply $cap, {}, ' ... and has no captures';
}

my $foo = Foo->new;
$foo->{one} = 1;

is($foo->one, 1, 'ro reads');
ok(exception { $foo->one(-3) }, 'ro dies on write attempt');
is($foo->one, 1, 'ro does not write');

is($foo->two, undef, 'rw reads');
$foo->two(-3);
is($foo->two, -3, 'rw writes');

is($foo->fifteen, 15, 'builder installs code sub');
is($foo->_build_fifteen, 15, 'builder installs code sub under the correct name');

is($foo->sixteen, 16, 'builder installs quote_sub');

{
  my $var = $gen->_sanitize_name('erk-qro yuf (fid)');
  eval qq{ my \$$var = 5; \$var };
  is $@, '', '_sanitize_name gives valid identifier';
}

done_testing;
