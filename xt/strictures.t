use strictures 1;
use Test::More;
use Test::Fatal;
use File::Temp;

delete $ENV{PERL_STRICTURES_EXTRA}; # ensure the env doesn't break the tests
$strictures::Smells_Like_VCS = 1;

# make sure these are really loaded
no indirect 'fatal';
no multidimensional;
no bareword::filehandles;

our %test_hash;

# inc hook to separate context
my $header = q{
#line 1 "%1$s/_t/%2$s.pm"
package %1$s::_t::%2$s;
use Moo;
};

my %checks = (
  multi => 'my $f = $::test_hash{1,2};',
  indirect => 'my $f = new Test::Builder;',
  bareword => 'open IO, ">", \(my $f);',
);

unshift @INC, sub {
  if ($_[1] =~ m{(.*)/_t/(.*)\.pm}) {
    my $content = sprintf($header, $1, $2) . $checks{$2} . "\n1;\n";
    open my $fh, '<', \$content;
    return $fh;
  }
  return;
};

my $multi_re = qr/Use of multidimensional array emulation/;
like exception { require t::_t::multi; }, $multi_re,
  'files in t get multidimensional strictures';
like exception { require lib::_t::multi; }, $multi_re,
  'files in lib get multidimensional strictures';
like exception { require xt::_t::multi; }, $multi_re,
  'files in xt get multidimensional strictures';
is exception { require other::_t::multi; }, undef,
  'files elsewhere don\'t get multidimensional strictures';

my $indirect_re = qr/Indirect call of method/;
like exception { require t::_t::indirect; }, $indirect_re,
  'files in t get indirect strictures';
like exception { require lib::_t::indirect; }, $indirect_re,
  'files in lib get indirect strictures';
like exception { require xt::_t::indirect; }, $indirect_re,
  'files in xt get indirect strictures';
is exception { require other::_t::indirect; }, undef,
  'files elsewhere don\'t get indirect strictures';

my $bareword_re = qr/Use of bareword filehandle/;
like exception { require t::_t::bareword; }, $bareword_re,
  'files in t get bareword strictures';
like exception { require lib::_t::bareword; }, $bareword_re,
  'files in lib get bareword strictures';
like exception { require xt::_t::bareword; }, $bareword_re,
  'files in xt get bareword strictures';
is exception { require other::_t::bareword; }, undef,
  'files elsewhere don\'t get bareword strictures';

done_testing;
