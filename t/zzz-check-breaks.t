use strict;
use warnings;
use Test::More;

my $meta;
BEGIN {
  eval { require Parse::CPAN::Meta; Parse::CPAN::Meta->VERSION(1.4200) }
    or plan skip_all => 'Parse::CPAN::Meta required for checking breakages';
  eval { require CPAN::Meta::Requirements }
    or plan skip_all => 'CPAN::Meta::Requirements required for checking breakages';
  my @meta_files = grep -f, qw(MYMETA.json MYMETA.yml META.json META.yml)
    or plan skip_all => 'no META file exists';
  for my $meta_file (@meta_files) {
    eval { $meta = Parse::CPAN::Meta->load_file($meta_file) }
      and last;
  }
  if (!$meta) {
    plan skip_all => 'unable to load any META files';
  }
}

use ExtUtils::MakeMaker;

my $breaks = $meta->{x_breaks};
my $req = CPAN::Meta::Requirements->from_string_hash( $breaks );

pass 'checking breakages...';

my @breaks;
for my $module ($req->required_modules) {
  (my $file = "$module.pm") =~ s{::}{/}g;
  my ($pm_file) = grep -e, map "$_/$file", @INC;
  next
    unless $pm_file;
  my $version = MM->parse_version($pm_file);
  next
    unless defined $version;
  (my $check_version = $version) =~ s/_//;
  if ($req->accepts_module($module, $version)) {
    my $broken_v = $breaks->{$module};
    $broken_v = ">= $broken_v"
      unless $broken_v =~ /\A\s*(?:==|>=|>|<=|<|!=)/;
    push @breaks, [$module, $check_version, $broken_v];
  }
}

if (@breaks) {
  diag "Installing Moo $meta->{version} will break these modules:\n\n"
  . (join '', map {
    "$_->[0] (found version $_->[1])\n"
    . "  Broken versions: $_->[2]\n"
  } @breaks)
  . "\nYou should now update these modules!";
}

done_testing;
