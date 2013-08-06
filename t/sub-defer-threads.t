use Config;
BEGIN {
  unless ($Config{useithreads}) {
    print "1..0 # SKIP your perl does not support ithreads\n";
    exit 0;
  }
}
use threads;
use strictures 1;
use Test::More;

use Sub::Defer;

my %made;

my $one_defer = defer_sub 'Foo::one' => sub {
  die "remade - wtf" if $made{'Foo::one'};
  $made{'Foo::one'} = sub { 'one' }
};

is(threads->create(sub {
  my $info = Sub::Defer::defer_info($one_defer);
  $info && $info->[0];
})->join, 'Foo::one', 'able to retrieve info in thread');

is(threads->create(sub {
  undefer_sub($one_defer);
  $made{'Foo::one'} && $made{'Foo::one'} == \&Foo::one && 1234;
})->join, 1234, 'able to undefer in thread');

done_testing;
