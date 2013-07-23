use strictures 1;
use Test::More;
use Config;
BEGIN {
  unless ($Config{useithreads} && eval { require threads } ) {
    plan skip_all => "your perl does not support ithreads";
  }
}

use Sub::Defer;

my %made;

my $one_defer = defer_sub 'Foo::one' => sub {
  die "remade - wtf" if $made{'Foo::one'};
  $made{'Foo::one'} = sub { 'one' }
};

ok(threads->create(sub {
  my $info = Sub::Defer::defer_info($one_defer);
  $info && $info->[0] eq 'Foo::one';
})->join, 'able to retrieve info in thread');

ok(threads->create(sub {
  undefer_sub($one_defer);
  $made{'Foo::one'} && $made{'Foo::one'} == \&Foo::one;
})->join, 'able to undefer in thread');

done_testing;
