use strictures 1;
use Test::More;
use Test::Fatal;

use Sub::Quote;

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

my $broken_quoted = quote_sub q{
  return 5<;
};

like(
  exception { $broken_quoted->() }, qr/Eval went very, very wrong/,
  "quoted sub with syntax error dies when called"
);

sub in_main { 1 }
is exception { quote_sub(q{ in_main(); })->(); }, undef, 'context preserved in quoted sub';

{
  no strict 'refs';
  is exception { quote_sub(q{ my $foo = "some_variable"; $$foo; })->(); }, undef, 'hints are preserved';
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
    if $] < 5.008000;
  my $eval_utf8 = eval 'sub { use utf8; eval Sub::Quote::quotify($_[0]) }';

  my @failed_utf8 = grep { my $o = $eval_utf8->($_); !defined $o || $o ne $_ }
    @strings;
  ok !@failed_utf8, "evaling quotify under utf8 returns same value for all strings"
    or diag "Failed strings: " . join(' ', map { $dump->($_) } @failed_utf8);
}

my @stuff = (qsub q{ print "hello"; }, 1, 2);
is scalar @stuff, 3, 'qsub only accepts a single parameter';

done_testing;
