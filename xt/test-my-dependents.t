use Test::More;
BEGIN {
  plan skip_all => <<'END_HELP' unless $ENV{MOO_TEST_MD} || @ARGV;
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

use Test::DependentModules qw( test_module );
use MetaCPAN::API;
use List::Util ();

# avoid any modules that depend on these
my @bad_prereqs = qw(Gtk2 Padre Wx);

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
            { not => { filter => {
              or => [
                map { { term => { 'dependency.module' => $_ } } } @bad_prereqs,
              ],
            } } }
          ],
        },
      },
    },
    size => 5000,
    fields => ['distribution', 'provides', 'metadata.provides'],
  },
);

my %bad_dist;
my $sec_reason;
my %skip;
my %todo;

my $hash;
for my $line (<DATA>) {
  chomp $line;
  next unless $line =~ /\S/;
  if ( $line =~ /^#\s*(\w+)(?::\s*(.*?)\s*)?$/ ) {
    die "Invalid action in DATA section ($1)"
      unless $1 eq 'SKIP' || $1 eq 'TODO';
    $hash = $1 eq 'SKIP' ? \%skip : \%todo;
    $sec_reason = $2;
  }

  my ( $dist, $reason ) = $line =~ /^(\S*)\s*(?:#\s*(.*?)\s*)?$/;
  next unless defined $dist && length $dist;

  $hash->{$dist} = $reason ? "$sec_reason: $reason" : $reason;
}

my %todo_module;
my @modules;
for my $hit (@{ $res->{hits}{hits} }) {
  my $dist = $hit->{fields}{distribution};
  next
    if exists $skip{$dist};
  next
    if $dist =~ /^(?:Task|Bundle|Acme)-/;

  my $module = (sort { length $a <=> length $b || $a cmp $b } do {
    if (my $provides = $hit->{fields}{provides}) {
      ref $provides ? @$provides : ($provides);
    }
    elsif (my $provides = $hit->{fields}{'metadata.provides'}) {
      keys %$provides;
    }
    else {
      (my $module = $dist) =~ s/-/::/g;
      ($module);
    }
  })[0];
  $todo_module{$module} = $todo{$dist}
    if exists $todo{$dist};
  push @modules, $module;
  $module;
}
@modules = sort @modules;

my @args = grep { $_ ne '--show' } @ARGV;
my $show = @args != @ARGV;
my $pick = $ENV{MOO_TEST_MD} || shift @args || 'all';

if ( $pick eq 'MooX' ) {
  @modules = grep /^MooX(?:$|::)/, @modules;
}
elsif ( $pick =~ /^\d+$/ ) {
  my $count = $pick == 1 ? 200 : $pick;
  diag(<<"EOF");
  Picking $count random dependents to test. Set MOO_TEST_MD=all to test all
  dependents or MOO_TEST_MD=MooX to test extension modules only.
EOF
  @modules = (List::Util::shuffle(@modules))[0 .. $count-1];
}
elsif ( $pick ne 'all' ) {
  my @chosen = split /,/, $ENV{MOO_TEST_MD};
  my %modules = map { $_ => 1 } @modules;
  if (my @unknown = grep { !$modules{$_} } @chosen) {
    die "Unknown modules: @unknown";
  }
  @modules = @chosen;
}

if ($show) {
  print "Dependents:\n";
  print "  $_\n" for @modules;
  exit;
}

plan tests => scalar @modules;
for my $module (@modules) {
  local $TODO = $todo_module{$module} || '???'
    if exists $todo_module{$module};
  test_module($module);
}


__DATA__

# SKIP: no tests
AnyMerchant
CPAN-Mirror-Finder
Catmandu-AlephX
Device-Hue
Novel-Robot
Novel-Robot-Browser
Novel-Robot-Parser
Novel-Robot-Packer
Thrift-API-HiveClient
Tiezi-Robot-Parser
Tiezi-Robot-Packer
WWW-ORCID

# TODO: broken
App-Presto
Catmandu-Store-Lucy
Dancer2-Session-Sereal
Dancer-Plugin-FontSubset
Data-Localize
DBIx-Class-IndexSearch-Dezi
DBIx-FixtureLoader
Message-Passing-ZeroMQ
Tak

# TODO: broken by perl 5.18
App-DBCritic                # 0.020 - smartmatch
App-OS-Detect-MachineCores  # 0.038 - smartmatch
Authen-HTTP-Signature       # 0.02 - smartmatch
DBICx-Backend-Move          # 1.000010 - smartmatch
POEx-ZMQ3                   # 0.060002 - smartmatch
Ruby-VersionManager         # 0.004003 - smartmatch
Text-Keywords               # 0.900 - smartmatch
Data-CloudWeights           # v0.9.2
HTML-Zoom-Parser-HH5P       # 0.002
Log-Message-Structured-Stringify-AsSereal   # 0.10

# TODO: broken prereqs
App-Netdisco
DBIx-Table-TestDataGenerator
Perinci-CmdLine
Perinci-Sub-Gen-AccessTable-DBI

# TODO: broken prereqs (perl 5.18)
App-Rssfilter   # 0.03 - Data::Alias
App-Zapzi       # 0.004 - HTTP::CookieJar
Code-Crypt      # 0.001000 - Crypt::DES
Data-Sah        # 0.15 - Regexp::Grammars
Language-Expr   # 0.19 - Regexp::Grammars
Net-Icecast2    # 0.005 - PHP::HTTPBuildQuery (hash order)
Org-To-HTML     # 0.07 - Language::Expr
POE-Component-ProcTerminator          # 0.03 - Log::Fu
Perinci-Access-Simple-Server          # 0.12 - Regexp::Grammars
Perinci-Sub-Gen-AccessTable           # 0.19 - Regexp::Grammars
Software-Release-Watch                # 0.01 - Data::Sah, Perinci::CmdLine
Software-Release-Watch-SW-wordpress   # 0.01 - Software::Release::Watch
Tiezi-Robot                           # 0.12 - Data::Dump::Streamer, SOAP::Lite
WebService-HabitRPG                   # 0.19 - Data::Alias

# TODO: broken tests
Template-Flute
Uninets-Check-Modules-HTTP
Uninets-Check-Modules-MongoDB
Uninets-Check-Modules-Redis
Net-OAuth-LP # pod coverage

# SKIP: invalid prereqs
Catmandu-Z3950        # 0.03 - ZOOM missing
Dancer2-Session-JSON  # 0.001 - Dancer2 bad version requirement

# SKIP: misc
Linux-AtaSmart    # OS specific
Net-Works         # 0.12 - prereq Math::Int128 (requires gcc 4.4)
XML-GrammarBase   # v0.2.2 - prereq XML::LibXSLT (hard to install)
Forecast-IO       # 0.21 - interactive tests

# TODO: broken by Moo change
Math-Rational-Approx        # RT#84035
App-Services                # RT#85255
Hg-Lib                      # pending release
