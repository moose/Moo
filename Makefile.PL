use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;

check_conflicts();
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %META = (
  name => 'Moo',
  license => 'perl_5',
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker'   => 0,
      'Dist::CheckConflicts'  => '0.02',
    } },
    build => { requires => {
    } },
    test => { requires => {
      'Test::More'  => 0.94,
      'Test::Fatal' => 0.003,
    } },
    runtime => { requires => {
      'perl'                      => 5.008001,
      'Class::Method::Modifiers'  => 1.10,  # for RT#80194
      'strictures'                => 1.004003,
      'Module::Runtime'           => 0.012, # for RT#74789
      'Role::Tiny'                => 1.003002,
      'Devel::GlobalDestruction'  => 0.11,  # for RT#78617
      'Dist::CheckConflicts'      => 0.02,
      'Import::Into'              => 1.002,
      ($] >= 5.010 ? () : ('MRO::Compat' => 0)),
    } },
    develop   => {
      requires => { map { $_ => 0 } qw(
        Class::XSAccessor
        indirect multidimensional bareword::filehandles
      ) },
      recommends => { map { $_ => 0 } qw(
        Moose Mouse namespace::clean namespace::autoclean
        MooseX::Types::Common::Numeric
        Type::Tiny
      ) },
    },
  },
  resources => {
    repository => {
      url => 'https://github.com/moose/Moo.git',
      web => 'https://github.com/moose/Moo',
      type => 'git',
    },
    x_IRC => 'irc://irc.perl.org/#moose',
    bugtracker => {
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Moo',
      mailto => 'bug-Moo@rt.cpan.org',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt' ]
  },
  Moo::Conflicts->can('conflicts') ? (
    x_breaks => { Moo::Conflicts->conflicts }
  ) : (),
);

my %MM_ARGS = (
  EXE_FILES => [
    'bin/moo-outdated',
  ],
);



# have to do this since old EUMM dev releases miss the eval $VERSION line
my $mmver = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta_works      = $mmver >= 6.57_07;
my $mymeta            = $mmver >= 6.57_02;
my $has_test_requires = $mmver >= 6.63_03;

my %configure_deps = %{$META{prereqs}{configure}{requires}};
my %build_deps     = %{$META{prereqs}{build}{requires}};
my %test_deps      = %{$META{prereqs}{test}{requires}};
my %run_deps       = %{$META{prereqs}{runtime}{requires}};

my $min_perl_version = delete $run_deps{perl};

if (not $has_test_requires) {
  %build_deps = (%build_deps, %test_deps);
  %test_deps = ();
}
if (not $mymeta_works) {
  %run_deps = (%run_deps, %build_deps);
  %build_deps = ();
}

(my $name = $META{name}) =~ s/-/::/g;
(my $module = "lib/$name.pm") =~ s{::}{/}g;

WriteMakefile(
  NAME => $META{name},
  VERSION_FROM => $module,
  LICENSE => $META{license},

  $min_perl_version     ? ( MIN_PERL_VERSION    => $min_perl_version ) : (),
  keys %configure_deps  ? ( CONFIGURE_REQUIRES  => \%configure_deps ) : (),
  keys %build_deps      ? ( BUILD_REQUIRES      => \%build_deps ) : (),
  keys %test_deps       ? ( TEST_REQUIRES       => \%test_deps ) : (),
  keys %run_deps        ? ( PREREQ_PM           => \%run_deps ) : (),

  ($mymeta && !$mymeta_works ? (NO_MYMETA => 1) : ()),
  -f 'META.yml' ? () : (META_ADD => { 'meta-spec' => { version => 2 }, %META }),

  %MM_ARGS,
);

# copied from Moose-2.0801/Makefile.PL
sub check_conflicts {
    if ( eval { require 'lib/Moo/Conflicts.pm'; 1; } ) {
        if ( eval { Moo::Conflicts->check_conflicts; 1 } ) {
            return;
        }
        else {
            my $err = $@;
            $err =~ s/^/    /mg;
            warn "***\n$err***\n";
        }
    }
    else {
        print <<'EOF';
***
    Your toolchain doesn't support configure_requires, so
    Dist::CheckConflicts hasn't been installed yet. You should check for
    conflicting modules manually using the 'moo-outdated' script that is
    installed with this distribution once the installation finishes.
***
EOF
    }

    return if $ENV{AUTOMATED_TESTING} || $ENV{NONINTERACTIVE_TESTING};

    # More or less copied from Module::Build
    return if $ENV{PERL_MM_USE_DEFAULT};
    return unless -t STDIN && ( -t STDOUT || !( -f STDOUT || -c STDOUT ) );
    return unless -f 'META.yml';

    sleep 4;
}

