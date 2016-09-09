use Moo::_strictures;
use Test::More;
use Test::Fatal;

use Sub::Quote qw(
  quote_sub
  quoted_from_sub
  unquote_sub
  qsub
  capture_unroll
  inlinify
  sanitize_identifier
);

our %EVALED;

my $one = quote_sub q{
    BEGIN { $::EVALED{'one'} = 1 }
    42
};

my $two = quote_sub q{
    BEGIN { $::EVALED{'two'} = 1 }
    3 + $x++
} => { '$x' => \do { my $x = 0 } };

ok(!keys %EVALED, 'Nothing evaled yet');

is unquote_sub(sub {}), undef,
  'unquote_sub returns undef for unknown subs';

my $u_one = unquote_sub $one;

is_deeply(
  [ sort keys %EVALED ], [ qw(one) ],
  'subs one evaled'
);

is($one->(), 42, 'One (quoted version)');

is($u_one->(), 42, 'One (unquoted version)');

is($two->(), 3, 'Two (quoted version)');
is(unquote_sub($two)->(), 4, 'Two (unquoted version)');
is($two->(), 5, 'Two (quoted version again)');

my $three = quote_sub 'Foo::three' => q{
    $x = $_[1] if $_[1];
    die +(caller(0))[3] if @_ > 2;
    return $x;
} => { '$x' => \do { my $x = 'spoon' } };

is(Foo->three, 'spoon', 'get ok (named method)');
is(Foo->three('fork'), 'fork', 'set ok (named method)');
is(Foo->three, 'fork', 're-get ok (named method)');
like(
  exception { Foo->three(qw(full cutlery set)) }, qr/Foo::three/,
  'exception contains correct name'
);

quote_sub 'Foo::four' => q{
  return 5;
};

my $quoted = quoted_from_sub(\&Foo::four);
like $quoted->[1], qr/return 5;/,
  'can get quoted from installed sub';
Foo::four();
my $quoted2 = quoted_from_sub(\&Foo::four);
like $quoted2->[1], qr/return 5;/,
  "can still get quoted from installed sub after undefer";
undef $quoted;

{
  package Bar;
  ::quote_sub blorp => q{ 1; };
}
ok defined &Bar::blorp,
  'bare sub name installed in current package';

my $long = "a" x 251;
is exception {
  (quote_sub "${long}a::${long}", q{ return 1; })->();
}, undef,
  'long names work if package and sub are short enough';

like exception {
  quote_sub "${long}${long}::${long}", q{ return 1; };
}, qr/^package name "$long$long" too long/,
  'over long package names error';

like exception {
  quote_sub "${long}::${long}${long}", q{ return 1; };
}, qr/^sub name "$long$long" too long/,
  'over long sub names error';

my $broken_quoted = quote_sub q{
  return 5<;
};

like(
  exception { $broken_quoted->() }, qr/Eval went very, very wrong/,
  "quoted sub with syntax error dies when called"
);

sub in_main { 1 }
is exception { quote_sub(q{ in_main(); })->(); }, undef,
  'package preserved from context';

{
  package Arf;
  sub in_arf { 1 }
}

is exception { quote_sub(q{ in_arf(); }, {}, { package => 'Arf' })->(); }, undef,
  'package used from options';

{
  use strict;
  no strict 'subs';
  local $TODO = "hints from caller not available on perl < 5.8"
    if "$]" < 5.008_000;
  like exception { quote_sub(q{ my $f = SomeBareword; ${"string_ref"} })->(); },
    qr/strict refs/,
    'hints preserved from context';
}

{
  my $hints;
  {
    use strict;
    no strict 'subs';
    BEGIN { $hints = $^H }
  }
  like exception { quote_sub(q{ my $f = SomeBareword; ${"string_ref"} }, {}, { hints => $hints })->(); },
    qr/strict refs/,
    'hints used from options';
}

{
  my $sub = do {
    no warnings;
    unquote_sub quote_sub(q{ 0 + undef });
  };
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $sub->();
  is scalar @warnings, 0,
    '"no warnings" preserved from context';
}

{
  my $sub = do {
    no warnings;
    use warnings;
    unquote_sub quote_sub(q{ 0 + undef });
  };
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $sub->();
  like $warnings[0],
    qr/uninitialized/,
    '"use warnings" preserved from context';
}

{
  my $warn_bits;
  eval q{
    use warnings FATAL => 'uninitialized';
    BEGIN { $warn_bits = ${^WARNING_BITS} }
    1;
  } or die $@;
  no warnings 'uninitialized';
  like exception { quote_sub(q{ 0 + undef }, {}, { warning_bits => $warn_bits })->(); },
    qr/uninitialized/,
    'warnings used from options';
}

BEGIN {
  package UseHintHash;
  $INC{'UseHintHash.pm'} = 1;

  sub import {
    $^H |= 0x020000;
    $^H{__PACKAGE__.'/enabled'} = 1;
  }
}

{
  my %hints;
  {
    BEGIN {
      $^H |= 0x020000;
      %^H = ();
    }
    use UseHintHash;
    BEGIN { %hints = %^H }
  }

  {
    local $TODO = 'hints hash from context not available on perl 5.8'
      if "$]" < 5.010_000;

    BEGIN {
      $^H |= 0x020000;
      %^H = ();
    }
    use UseHintHash;
    is_deeply quote_sub(q{
      our %temp_hints_hash;
      BEGIN { %temp_hints_hash = %^H }
      \%temp_hints_hash;
    })->(), \%hints,
      'hints hash preserved from context';
  }

  is_deeply quote_sub(q{
    our %temp_hints_hash;
    BEGIN { %temp_hints_hash = %^H }
    \%temp_hints_hash;
  }, {}, { hintshash => \%hints })->(), \%hints,
    'hints hash used from options';
}

{
  BEGIN { %^H = () }
  my $sub = quote_sub(q{
    our %temp_hints_hash;
    BEGIN { %temp_hints_hash = %^H }
    \%temp_hints_hash;
  });
  my $wrap_sub = do {
    use UseHintHash;
    my (undef, $code, $cap) = @{quoted_from_sub($sub)};
    quote_sub $code, $cap||();
  };
  is_deeply $wrap_sub->(), {}, 'empty hints maintained when inlined';
}

BEGIN {
  package BetterNumbers;
  $INC{'BetterNumbers.pm'} = 1;
  use overload ();

  sub import {
    my ($class, $add) = @_;
    # closure vs not
    if (defined $add) {
      overload::constant 'integer', sub { $_[0] + $add };
    }
    else {
      overload::constant 'integer', sub { $_[0] + 1 };
    }
  }
}

{
  my ($options, $context_sub, $direct_val);
  {
    use BetterNumbers;
    BEGIN { $options = { hints => $^H, hintshash => { %^H } } }
    $direct_val = 10;
    $context_sub = quote_sub(q{ 10 });
  }
  my $options_sub = quote_sub(q{ 10 }, {}, $options);

  is $direct_val, 11,
    'integer overload is working';

  local $TODO = "refs in hints hash not yet implemented";
  {
    my $context_val;
    is exception { $context_val = $context_sub->() }, undef,
      'hints hash refs from context not broken';
    local $TODO = 'hints hash from context not available on perl 5.8'
      if !$TODO && "$]" < 5.010_000;
    is $context_val, 11,
      'hints hash refs preserved from context';
  }

  {
    my $options_val;
    is exception { $options_val = $options_sub->() }, undef,
      'hints hash refs from options not broken';
    is $options_val, 11,
      'hints hash refs used from options';
  }
}

{
  my ($options, $context_sub, $direct_val);
  {
    use BetterNumbers +2;
    BEGIN { $options = { hints => $^H, hintshash => { %^H } } }
    $direct_val = 10;
    $context_sub = quote_sub(q{ 10 });
  }
  my $options_sub = quote_sub(q{ 10 }, {}, $options);

  is $direct_val, 12,
    'closure integer overload is working';

  local $TODO = "refs in hints hash not yet implemented";

  {
    my $context_val;
    is exception { $context_val = $context_sub->() }, undef,
      'hints hash closure refs from context not broken';
    local $TODO = 'hints hash from context not available on perl 5.8'
      if !$TODO && "$]" < 5.010_000;
    is $context_val, 12,
      'hints hash closure refs preserved from context';
  }

  {
    my $options_val;
    is exception { $options_val = $options_sub->() }, undef,
      'hints hash closure refs from options not broken';
    is $options_val, 12,
      'hints hash closure refs used from options';
  }
}

{
  my $foo = quote_sub '{}';
  my $foo_string = "$foo";
  undef $foo;

  is quoted_from_sub($foo_string), undef,
    "quoted subs don't leak";

  Sub::Quote->CLONE;
  ok !exists $Sub::Quote::QUOTED{$foo_string},
    'CLONE cleans out expired entries';
}

{
  my $foo = quote_sub '{}';
  my $foo_string = "$foo";
  Sub::Quote->CLONE;
  undef $foo;

  is quoted_from_sub($foo_string), undef,
    "CLONE doesn't strengthen refs";
}

{
  my $foo = quote_sub '{}';
  my $foo_string = "$foo";
  my $foo_info = quoted_from_sub($foo_string);
  undef $foo;

  is exception { Sub::Quote->CLONE }, undef,
    'CLONE works when quoted info saved externally';
  ok exists $Sub::Quote::QUOTED{$foo_string},
    'CLONE keeps entries that had info saved';
}

{
  my $foo = quote_sub '{}';
  my $foo_string = "$foo";
  my $foo_info = $Sub::Quote::QUOTED{$foo_string};
  undef $foo;

  is exception { Sub::Quote->CLONE }, undef,
    'CLONE works when quoted info kept alive externally';
  ok !exists $Sub::Quote::QUOTED{$foo_string},
    'CLONE removes expired entries that were kept alive externally';
}

{
  my $foo = quote_sub '{}';
  my $foo_string = "$foo";
  my $sub = unquote_sub $foo;
  my $sub_string = "$sub";

  Sub::Quote->CLONE;

  ok quoted_from_sub($sub_string),
    'CLONE maintains entries referenced by unquoted sub';

  undef $sub;
  ok quoted_from_sub($foo_string)->[3],
    'unquoted sub still available if quoted sub exists';
}

{
  my $foo = quote_sub '{}';
  my $foo_string = "$foo";
  my $foo2 = unquote_sub $foo;
  undef $foo;

  my $foo_info = Sub::Quote::quoted_from_sub($foo_string);
  is $foo_info, undef,
    'quoted data not maintained for quoted sub deleted after being unquoted';

  is quoted_from_sub($foo2)->[3], $foo2,
    'unquoted sub still included in quote info';
}

use Data::Dumper;
my $dump = sub {
  local $Data::Dumper::Terse = 1;
  my $d = Data::Dumper::Dumper($_[0]);
  $d =~ s/\s+$//;
  $d;
};

my @strings   = (0, 1, "\x00", "a", "\xFC", "\x{1F4A9}");
my $eval = sub { eval Sub::Quote::quotify($_[0])};

my @failed = grep { my $o = $eval->($_); !defined $o || $o ne $_ } @strings;

ok !@failed, "evaling quotify returns same value for all strings"
  or diag "Failed strings: " . join(' ', map { $dump->($_) } @failed);

SKIP: {
  skip "working utf8 pragma not available", 1
    if "$]" < 5.008_000;
  my $eval_utf8 = eval 'sub { use utf8; eval Sub::Quote::quotify($_[0]) }';

  my @failed_utf8 = grep { my $o = $eval_utf8->($_); !defined $o || $o ne $_ }
    @strings;
  ok !@failed_utf8, "evaling quotify under utf8 returns same value for all strings"
    or diag "Failed strings: " . join(' ', map { $dump->($_) } @failed_utf8);
}

unlike Sub::Quote::quotify($_), qr/[^0-9.-]/,
  "quotify preserves $_ as number"
  for 0, 1, 1.5, 0.5, -10;

my @stuff = (qsub q{ print "hello"; }, 1, 2);
is scalar @stuff, 3, 'qsub only accepts a single parameter';

my $captures = {
  '$x' => \1,
  '$y' => \2,
};
my $prelude = capture_unroll '$captures', $captures, 4;
my $out = eval
  $prelude
  . '[ $x, $y ]';
is "$@", '', 'capture_unroll produces valid code';
is_deeply $out, [ 1, 2 ], 'unrolled variables get correct values';

like exception {
  capture_unroll '$captures', { '&foo' => \sub { 5 } }, 4;
}, qr/^capture key should start with @, % or \$/,
  'capture_unroll rejects vars other than scalar, hash, or array';

{
  my $inlined_code = inlinify q{
    my ($x, $y) = @_;

    [ $x, $y ];
  }, '$x, $y', $prelude;
  my $out = eval $inlined_code;
  is "$@", '', 'inlinify produces valid code'
    or diag "code:\n$inlined_code";
  is_deeply $out, [ 1, 2 ], 'inlinified code get correct values';
  unlike $inlined_code, qr/my \(\$x, \$y\) = \@_;/,
    "matching variables aren't reassigned";
}

{
  $Bar::baz = 3;
  my $inlined_code = inlinify q{
    package Bar;
    my ($x, $y) = @_;

    [ $x, $y, our $baz ];
  }, '$x, $y', $prelude;
  my $out = eval $inlined_code;
  is "$@", '', 'inlinify produces valid code'
    or diag "code:\n$inlined_code";
  is_deeply $out, [ 1, 2, 3 ], 'inlinified code get correct values';
  unlike $inlined_code, qr/my \(\$x, \$y\) = \@_;/,
    "matching variables aren't reassigned";
}

{
  my $inlined_code = inlinify q{
    my ($d, $f) = @_;

    [ $d, $f ];
  }, '$x, $y', $prelude;
  my $out = eval $inlined_code;
  is "$@", '', 'inlinify with unmatched params produces valid code'
    or diag "code:\n$inlined_code";
  is_deeply $out, [ 1, 2 ], 'inlinified code get correct values';
}

{
  my $inlined_code = inlinify q{
    my $z = $_[0];
    $z;
  }, '$y', $prelude;
  my $out = eval $inlined_code;
  is "$@", '', 'inlinify with out @_ produces valid code'
    or diag "code:\n$inlined_code";
  is $out, 2, 'inlinified code get correct values';
}

{
  my @warnings;
  local $ENV{SUB_QUOTE_DEBUG} = 1;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $sub = quote_sub q{ "this is in the quoted sub" };
  $sub->();
  like $warnings[0],
    qr/sub\s*{.*this is in the quoted sub/s,
    'got debug info with SUB_QUOTE_DEBUG';
}

{
  my $sub = quote_sub q{
    BEGIN { $::EVALED{'no_defer'} = 1 }
    1;
  }, {}, {no_defer => 1};
  is $::EVALED{no_defer}, 1,
    'evaled immediately with no_defer option';
}

{
  my $sub = quote_sub 'No::Defer::Test', q{
    BEGIN { $::EVALED{'no_defer'} = 1 }
    1;
  }, {}, {no_defer => 1};
  is $::EVALED{no_defer}, 1,
    'evaled immediately with no_defer option (named)';
  ok defined &No::Defer::Test,
    'sub installed with no_defer option';
}

{
  my $caller;
  sub No::Install::Tester {
    $caller = (caller(1))[3];
  }
  my $sub = quote_sub 'No::Install::Test', q{
    No::Install::Tester();
  }, {}, {no_install => 1};
  ok !defined &No::Install::Test,
    'sub not installed with no_install option';
  $sub->();
  is $caller, 'No::Install::Test',
    'sub named properly with no_install option';
}

{
  my $caller;
  sub No::Install::No::Defer::Tester {
    $caller = (caller(1))[3];
  }
  my $sub = quote_sub 'No::Install::No::Defer::Test', q{
    No::Install::No::Defer::Tester();
  }, {}, {no_install => 1, no_defer => 1};
  ok !defined &No::Install::No::Defer::Test,
    'sub not installed with no_install and no_defer options';
  $sub->();
  is $caller, 'No::Install::No::Defer::Test',
    'sub named properly with no_install and no_defer options';
}

my $var = sanitize_identifier('erk-qro yuf (fid)');
eval qq{ my \$$var = 5; \$var };
is $@, '', 'sanitize_identifier gives valid identifier';

{
  my $var;
  my $sub = quote_sub q{ $$var }, { '$var' => \\$var }, { attributes => [ 'lvalue' ] };
  $sub->() = 5;
  is $var, 5,
    'attributes applied to quoted sub';
}

{
  my $var;
  my $sub = quote_sub q{ $$var }, { '$var' => \\$var }, { attributes => [ 'lvalue' ], no_defer => 1 };
  $sub->() = 5;
  is $var, 5,
    'attributes applied to quoted sub with no_defer';
}

done_testing;
