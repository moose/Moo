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
use Cwd ();
use Config;

my @extra_libs = do {
  my @libs = `"$^X" -le"print for \@INC"`;
  chomp @libs;
  my %libs; @libs{@libs} = ();
  map { Cwd::abs_path($_) } grep { !exists $libs{$_} } @INC;
};
$ENV{PERL5LIB} = join($Config{path_sep}, @extra_libs, $ENV{PERL5LIB}||());

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
my %skip_module;
my @modules;
for my $hit (@{ $res->{hits}{hits} }) {
  my $dist = $hit->{fields}{distribution};

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
  $skip_module{$module} = $skip{$dist}
    if exists $skip{$dist};
  if ($dist =~ /^(Task|Bundle|Acme)-/) {
    $skip_module{$module} = "not testing $1 dist";
  }
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
  @modules = grep { !exists $skip_modules{$_} } List::Util::shuffle(@modules);
  @modules = @modules[0 .. $count-1];
}
elsif ( $pick ne 'all' ) {
  my @chosen = split /,/, $pick;
  my %modules = map { $_ => 1 } @modules;
  if (my @unknown = grep { !$modules{$_} } @chosen) {
    die "Unknown modules: @unknown";
  }
  delete @skip_modules{@chosen};
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
  SKIP: {
    local $TODO = $todo_module{$module} || '???'
      if exists $todo_module{$module};
    skip "$module - " . ($skip_module{$module} || '???'), 1
      if exists $skip_module{$module};
    test_module($module);
  }
}


__DATA__

# TODO: broken
App-Presto                  # 0.009
Dancer2-Session-Sereal      # 0.001
Mail-GcalReminder           # 0.1
DBIx-Class-IndexSearch-Dezi # 0.05
Tak                         # 0.001003
HTML-Zoom-Parser-HH5P       # 0.002
Farabi                      # 0.44
MooX-Types-CLike            # 0.92
Net-Easypost                # 0.09
OAuth2-Google-Plus          # 0.02
Protocol-Star-Linemode      # 1.0.0
Vim-X                       # 0.2.0
WWW-eNom                    # v1.2.8 - the internet changes
WebService-Cryptsy          # 1.008003
Dancer2-Plugin-REST         # 0.21
Config-GitLike              # 1.13
WWW-ThisIsMyJam             # v0.1.0
Dancer2-Session-JSON        # 0.001
App-Kit                     # 0.26 - db test segfaults
Data-Record-Serialize       # 0.05 - dbi test fails

# TODO: broken prereqs
Dancer-Plugin-FontSubset    # 0.1.2 - Font::TTF::Scripts::Name
App-Unicheck-Modules-MySQL  # 0.02 - DBD::mysql
Video-PlaybackMachine       # 0.09 - needs X11::FullScreen
Games-Snake                 # 0.000001 - SDL
Data-SimplePassword         # 0.10 - Crypt::Random, Math::Pari
Dancer2-Plugin-Queue        # 0.004 - Dancer2 0.08
MarpaX-Grammar-GraphViz2    # 1.00 - GraphViz2
Nitesi                      # 0.0094 - Crypt::Random, Math::Pari
POEx-ZMQ3                   # 0.060003 - ZMQ::LibZMQ3
Unicorn-Manager             # 0.006009 - Net::Interface
Wight-Chart                 # 0.003 - Wight
Yakuake-Sessions            # 0.11.1 - Net::DBus
Jedi-Plugin-Auth            # 0.01 - Jedi
Minilla                     # v0.14.1
Perinci-CmdLine                       # 0.85 - via SHARYANTO
Perinci-To-Text                       # 0.22 - via SHARYANTO
Perinci-Sub-To-Text                   # 0.24 - via SHARYANTO
Software-Release-Watch                # 0.01 - via SHARYANTO
Software-Release-Watch-SW-wordpress   # 0.01 - via Software::Release::Watch
Org-To-HTML                 # 0.11 - via Perinci::*

# TODO: undeclared prereqs
Catmandu-Inspire            # v0.24 - Furl

# TODO: broken by perl 5.18
App-DBCritic                # 0.020 - smartmatch (GH #9)
Authen-HTTP-Signature       # 0.02 - smartmatch (rt#88854)
DBICx-Backend-Move          # 1.000010 - smartmatch (rt#88853)
Ruby-VersionManager         # 0.004003 - smartmatch (rt#88852)
Text-Keywords               # 0.900 - smartmatch (rt#84339)
WebService-HabitRPG         # 0.21 - smartmatch (rt#88399)
Net-Icecast2                # 0.005 - hash order via PHP::HTTPBuildQuery (rt#81570)
POE-Component-ProcTerminator  # 0.03 - hash order via Log::Fu (rt#88851)
Plugin-Tiny                 # 0.012 - hash order
Firebase                    # 0.0201 - hash order

# TODO: broken by Regexp::Grammars (perl 5.18)
Language-Expr   # 0.19
Org-To-HTML     # 0.07 - via Language::Expr
Perinci-Access-Simple-Server          # 0.12

# TODO: invalid prereqs
Catmandu-Z3950        # 0.03 - ZOOM missing
Dancer2-Session-JSON  # 0.001 - Dancer2 bad version requirement
Business-CPI-Gateway-Moip # 0.05 - Business::CPI::Buyer
Business-OnlinePayment-IPayment # 0.05 - XML::Compile::WSDL11
WebService-BambooHR   # 0.04 - LWP::Online
WWW-AdServeApache2-HttpEquiv # 1.00r - unlisted dep Geo::IP
WWW-AdServer          # 1.01 - unlisted dep Geo::IP
CatalystX-Usul        # 0.17.1 - issues in prereq chain
Dancer2-Template-Haml # 0.04 - unlisted dep Text::Haml

# SKIP: misc
Apache2-HttpEquiv     # 1.00 - prereq Apache2::Const
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
App-PerlWatcher-Watcher-FileTail # 0.18 - Linux::Inotify2
switchman               # 1.05 - Linux::MemInfo
Juno                    # 0.009 - never finishes
Zucchini                # 0.0.21 - broken by File::Rsync
ZMQ-FFI                 # 0.12 - libzmq
MaxMind-DB-Reader-XS    # 0.060003 - external lib libmaxminddb
Cave-Wrapper            # 0.01100100 - external program cave
Tropo                   # 0.16 - openssl >= 1.0.0?

# TODO: broken by Moo change
Math-Rational-Approx        # RT#84035
App-Services                # RT#85255
Hg-Lib                      # pending release
