use Config;
BEGIN {
  unless ($Config{useithreads}) {
    print "1..0 # SKIP your perl does not support ithreads\n";
    exit 0;
  }
  if ($] <= 5.008004) {
    print "1..0 # SKIP threads not reliable enough on perl <= 5.8.4\n";
    exit 0;
  }
}
use threads;
use Moo::_strictures;
use Test::More;

use Sub::Defer;

my %made;

my $one_defer = defer_sub 'Foo::one' => sub {
  die "remade - wtf" if $made{'Foo::one'};
  $made{'Foo::one'} = sub { 'one' };
};

ok(threads->create(sub {
  my $info = Sub::Defer::defer_info($one_defer);
  my $name = $info && $info->[0] || '[undef]';
  my $ok = $name eq 'Foo::one';
  if (!$ok) {
    print STDERR "#   Bad sub name when undeferring: $name\n";
  }
  return $ok ? 1234 : 0;
})->join == 1234, 'able to retrieve info in thread');

ok(threads->create(sub {
  undefer_sub($one_defer);
  my $ok = $made{'Foo::one'} && $made{'Foo::one'} == \&Foo::one;
  return $ok ? 1234 : 0;
})->join == 1234, 'able to undefer in thread');

done_testing;
