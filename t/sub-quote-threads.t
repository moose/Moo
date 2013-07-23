use strictures 1;
use Test::More;
use Config;
BEGIN {
  unless ($Config{useithreads} && eval { require threads } ) {
    plan skip_all => "your perl does not support ithreads";
  }
}

use Sub::Quote;

my $one = quote_sub my $one_code = q{
    BEGIN { $::EVALED{'one'} = 1 }
    42
};

my $two = quote_sub q{
    BEGIN { $::EVALED{'two'} = 1 }
    3 + $x++
} => { '$x' => \do { my $x = 0 } };

ok(threads->create(sub {
  my $quoted = quoted_from_sub($one);
  $quoted && $quoted->[1] eq $one_code;
})->join, 'able to retrieve quoted sub in thread');

my $u_one = unquote_sub $one;

is(threads->create(sub { $one->() })->join, 42, 'One (quoted version)');

is(threads->create(sub { $u_one->() })->join, 42, 'One (unquoted version)');

my $r = threads->create(sub {
  my @r;
  push @r, $two->();
  push @r, unquote_sub($two)->();
  push @r, $two->();
  \@r;
})->join;

is($r->[0], 3, 'Two in thread (quoted version)');
is($r->[1], 4, 'Two in thread (unquoted version)');
is($r->[2], 5, 'Two in thread (quoted version again)');

done_testing;