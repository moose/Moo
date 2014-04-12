use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require CPAN::Meta::Requirements }
    or plan skip_all => 'CPAN::Meta::Requirements required for checking breakages';
}

use ExtUtils::MakeMaker;
use Module::Runtime qw(module_notional_filename);
use Moo ();

my $req = CPAN::Meta::Requirements->from_string_hash( {
  'HTML::Restrict' => '== 2.1.5',
} );

pass 'checking breakages...';

my @breaks;
for my $module ($req->required_modules) {
  my ($pm_file) = grep -e, map $_.'/'.module_notional_filename($module), @INC;
  next
    unless $pm_file;
  my $version = MM->parse_version($pm_file);
  next
    unless defined $version;
  (my $check_version = $version) =~ s/_//;
  if ($req->accepts_module($module, $version)) {
    my $broken_v = $req->requirements_for_module($module);
    $broken_v = ">= $broken_v"
      unless $broken_v =~ /\A\s*(?:==|>=|>|<=|<|!=)/;
    push @breaks, [$module, $check_version, $broken_v];
  }
}

if (@breaks) {
  diag "Installing Moo $Moo::VERSION will break these modules:\n\n"
  . (join '', map {
    "$_->[0] (found version $_->[1])\n"
    . "  Broken versions: $_->[2]\n"
  } @breaks)
  . "\nYou should now update these modules!";
}

done_testing;
