use B ();
BEGIN { delete $B::{perlstring} };
use Moo::_strictures;
use Test::More;
use Test::Fatal;

{
  package MyClass;
  use Moo;
  my $string = join('', "\x00" .. "\x7F");
  has foo => (is => 'ro', default => $string);
  ::is +__PACKAGE__->new->foo, $string,
    "can quote arbitrary strings 5.6 style";
}

done_testing;
