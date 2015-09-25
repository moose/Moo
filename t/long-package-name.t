use Moo::_strictures;
use Test::More;
use Test::Fatal;

{
  package Some::Class;
  use Moo;
  has attr1 => (is => 'ro');
}

my $max_length = 252;

my $long_name = "Long::Package::Name::";
$long_name .= substr("0123456789" x 26, 0, $max_length - length $long_name);

is exception {
  eval qq{
    package $long_name;
    use Moo;
    has attr2 => (is => 'ro');
    1;
  } or die "$@";
}, undef,
  'can use Moo in a long package';

is exception {
  $long_name->new;
}, undef,
  'long package name instantiation works';

done_testing;
