use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;

check_conflicts();
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %CONFIGURE_DEPS = (
  'ExtUtils::MakeMaker' => 0,
  'Dist::CheckConflicts' => '0.02',
);
my %BUILD_DEPS = ();

my %TEST_DEPS = (
  'Test::More' => 0.94,
  'Test::Fatal' => 0.003,
);

my %RUN_DEPS = (
  'Class::Method::Modifiers' => 1.10, # or RT#80194
  'strictures' => 1.004003,
  'Module::Runtime' => 0.012, # for RT#74789
  'Role::Tiny' => 1.003000,
  'Devel::GlobalDestruction' => 0.11, # for RT#78617
  'Dist::CheckConflicts' => 0.02,
);

my %extra_info = (
  'meta-spec' => { version => 2 },
  resources => {
    repository => {
      url => 'git://git.shadowcat.co.uk/gitmo/Moo.git',
      web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=gitmo/Moo.git',
      type => 'git',
    },
    x_IRC => 'irc://irc.perl.org/#moose',
    bugtracker => {
      web => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Moo',
      mailto => 'bug-moo@rt.cpan.org',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  prereqs => {
    configure => { requires => { %CONFIGURE_DEPS } },
    build     => { requires => { %BUILD_DEPS } },
    test      => { requires => { %TEST_DEPS } },
    runtime   => { requires => { %RUN_DEPS, perl => '5.8.1' } },
  },
);

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $mymeta_works = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.57_07 };
my $mymeta = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.57_02 };

my $has_test_requires = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.63_03 };

my $has_meta_v2 = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.57_10 };

if (! $has_meta_v2) {
  %extra_info = ();
}
if (not $has_test_requires) {
  %BUILD_DEPS = (%BUILD_DEPS, %TEST_DEPS);
  %TEST_DEPS = ();
}
if (not $mymeta_works) {
  %RUN_DEPS = (%RUN_DEPS, %BUILD_DEPS);
  %BUILD_DEPS = ();
}

WriteMakefile(
  NAME => 'Moo',
  VERSION_FROM => 'lib/Moo.pm',
  CONFIGURE_REQUIRES => \%CONFIGURE_DEPS,
  PREREQ_PM => {
    %RUN_DEPS,
    ($] >= 5.010 ? () : ('MRO::Compat' => 0)),
  },
  keys %BUILD_DEPS ? ( BUILD_REQUIRES => \%BUILD_DEPS ) : (),
  keys %TEST_DEPS ? ( TEST_REQUIRES => \%TEST_DEPS ) : (),
  META_ADD => \%extra_info,
  META_MERGE => {
    no_index => {
      directory => [ 'xt' ]
    },
    Moo::Conflicts->can('conflicts') ? (
      x_breaks => { Moo::Conflicts->conflicts }
    ) : (),
  },
  ($mymeta && !$mymeta_works ? (NO_MYMETA => 1) : ()),
  LICENSE => 'perl',
  EXE_FILES => [
    'bin/moo-outdated',
  ],
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

    sleep 4;
}

