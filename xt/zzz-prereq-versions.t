use strict;
use warnings;
use Test::More;

my $meta_file;
BEGIN {
  $ENV{CONTINUOUS_INTEGRATION}
    or plan skip_all => 'Only runs under CONTINUOUS_INTEGRATION';
  eval { require Parse::CPAN::Meta; Parse::CPAN::Meta->VERSION(1.4200) }
    or plan skip_all => 'Parse::CPAN::Meta required for checking breakages';
  ($meta_file) = grep -f, qw(MYMETA.json MYMETA.yml META.json META.yml)
    or plan skip_all => 'no META file exists';
}

use ExtUtils::MakeMaker;

my $meta = Parse::CPAN::Meta->load_file($meta_file);
my %seen = (perl => 1);
my @prereqs =
  sort
  grep !$seen{$_}++,
  'Devel::StackTrace',
  'Package::Stash',
  'Package::Stash::XS',
  'Eval::Closure',
  map keys %$_,
  map values %$_,
  values %{$meta->{prereqs}};

pass 'reporting prereqs...';

for my $module (@prereqs) {
  (my $file = "$module.pm") =~ s{::}{/}g;
  my ($pm_file) = grep -e, map "$_/$file", @INC;
  my $version = $pm_file ? MM->parse_version($pm_file) : 'missing';
  $version = '[undef]' if !defined $version;
  diag sprintf "%-40s %s", $module, $version;
}

done_testing;
