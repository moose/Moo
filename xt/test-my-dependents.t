use Test::More;
BEGIN {
  plan skip_all => <<'END_HELP' unless $ENV{MOO_TEST_MD};
This test will not run unless you set MOO_TEST_MD to a true value.

  Valid values are:

     all                  Test every dist which depends on Moose except those
                          that we know cannot be tested. This is a lot of
                          distros (hundreds).

     Dist::1,Dist::2,...  Test the individual dists listed.

     MooX                 Test all Moo extension distros.

     1                    Run the default tests. We pick 200 random dists and
                          test them.
END_HELP
}

use Test::DependentModules qw( test_modules );
use MetaCPAN::API;
use List::Util ();

my $mcpan = MetaCPAN::API->new;
my $res = $mcpan->post(
  '/search/reverse_dependencies/Moo' => {
    query => {
      filtered => {
        query => { "match_all" => {} },
        filter => {
          and => [
            { term => { 'release.status' => 'latest' } },
            { term => { 'release.authorized' => \1 } },
          ],
        },
      },
    },
    size => 5000,
    fields => ['distribution', 'provides'],
  },
);

my %bad_module;
foreach my $line (<DATA>) {
  chomp $line;
  if ($line =~ /^\s*(\S+)\s*(#|$)/) {
    $bad_module{$1}++;
  }
  else {
    die "Invalid entry in DATA section: $line";
  }
}

my @modules = sort grep !/^(?:Task|Bundle|Acme)::/, grep !$bad_module{$_}, map {
  if (my $provides = $_->{fields}{provides}) {
    ref $provides ? (sort @$provides)[0] : $provides;
  }
  else {
    my $dist = $_->{fields}{distribution};
    $dist =~ s/-/::/g;
    $dist;
  }
} @{ $res->{hits}{hits} };

if ( $ENV{MOO_TEST_MD} eq 'MooX' ) {
  @modules = grep /^MooX(?:$|::)/, @modules;
}
elsif ( $ENV{MOO_TEST_MD} eq '1' ) {
  diag(<<'EOF');
  Picking 200 random dependents to test. Set MOO_TEST_MD=all to test all
  dependents or MOO_TEST_MD=MooX to test extension modules only.
EOF
  @modules = (List::Util::shuffle(@modules))[0..199];
}
elsif ( $ENV{MOO_TEST_MD} ne 'all' ) {
  my @chosen = split /,/, $ENV{MOO_TEST_MD};
  my %modules = map { $_ => 1 } @modules;
  if (my @unknown = grep { !$modules{$_} } @chosen) {
      die "Unknown modules: @unknown";
  }
  @modules = @chosen;
}

plan tests => scalar @modules;
test_modules(@modules);

__DATA__
# broken

