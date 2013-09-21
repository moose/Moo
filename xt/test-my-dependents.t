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

# TODO: broken
App-Presto                  # 0.009
Dancer2-Session-Sereal      # 0.001
Mail-GcalReminder           # 0.1
DBIx-Class-IndexSearch-Dezi # 0.05
Tak                         # 0.001003
HTML-Zoom-Parser-HH5P       # 0.002

# TODO: broken prereqs
Dancer-Plugin-FontSubset    # 0.1.2 - Font::TTF::Scripts::Name

# TODO: broken by perl 5.18
App-DBCritic                # 0.020 - smartmatch (GH #9)
App-OS-Detect-MachineCores  # 0.038 - smartmatch (rt#88855)
Authen-HTTP-Signature       # 0.02 - smartmatch (rt#88854)
DBICx-Backend-Move          # 1.000010 - smartmatch (rt#88853)
Ruby-VersionManager         # 0.004003 - smartmatch (rt#88852)
Text-Keywords               # 0.900 - smartmatch (rt#84339)
Log-Message-Structured-Stringify-AsSereal   # 0.10 - hash order (GH #1)
WebService-HabitRPG         # 0.21 - smartmatch (rt#88399)
App-Rssfilter               # 0.03 - smartmatch (GH #2)
Net-Icecast2                # 0.005 - hash order via PHP::HTTPBuildQuery (rt#81570)
POE-Component-ProcTerminator  # 0.03 - hash order via Log::Fu (rt#88851)

# TODO: broken by Regexp::Grammars (perl 5.18)
Data-Sah        # 0.15
Language-Expr   # 0.19
Org-To-HTML     # 0.07 - via Language::Expr
Perinci-Access-Simple-Server          # 0.12
Perinci-CmdLine                       # 0.85 - via Data::Sah
Perinci-To-Text                       # 0.22 - via Data::Sah
Perinci-Sub-To-Text                   # 0.24 - via Data::Sah
Finance-Bank-ID-BCA                   # 0.26 - via Perinci::CmdLine
Software-Release-Watch                # 0.01 - via Data::Sah, Perinci::CmdLine
Software-Release-Watch-SW-wordpress   # 0.01 - via Software::Release::Watch

# SKIP: invalid prereqs
Catmandu-Z3950        # 0.03 - ZOOM missing
Dancer2-Session-JSON  # 0.001 - Dancer2 bad version requirement

# SKIP: misc
GeoIP2            # 0.040000 - prereq Math::Int128 (requires gcc 4.4)
Graphics-Potrace  # 0.72 - external dependency
GraphViz2         # 2.19 - external dependency
Linux-AtaSmart    # OS specific
MaxMind-DB-Reader # 0.040003 - prereq Math::Int128 (requires gcc 4.4)
MaxMind-DB-Common # 0.031002 - prereq Math::Int128 (requires gcc 4.4)
Net-Works         # 0.12 - prereq Math::Int128 (requires gcc 4.4)
PortageXS         # 0.3.1 - external dependency and broken prereq (Shell::EnvImporter)
XML-GrammarBase   # v0.2.2 - prereq XML::LibXSLT (hard to install)
Forecast-IO       # 0.21 - interactive tests
Net-OpenVPN-Launcher    # 0.1 - external dependency (and broken test)
App-PerlWatcher-Level   # 0.13 - depends on Linux::Inotify2
Graph-Easy-Marpa        # 2.00 - GraphVis2
Net-OAuth-LP            # 0.016 - relies on external service
Message-Passing-ZeroMQ  # 0.007 - external dependency
Net-Docker              # 0.002003 - external dependency

# TODO: broken by Moo change
Math-Rational-Approx        # RT#84035
App-Services                # RT#85255
Hg-Lib                      # pending release
