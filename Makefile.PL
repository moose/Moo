use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;

check_conflicts();
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %BUILD_DEPS = ();

my %TEST_DEPS = (
  'Test::More' => 0.96,
  'Test::Fatal' => 0.003,
);

my %RUN_DEPS = (
  'Class::Method::Modifiers' => 1.10,
  'strictures' => 1.004003,
  'Module::Runtime' => 0.012,
  'Role::Tiny' => 1.002004,
  'Devel::GlobalDestruction' => 0.11,
);

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $mymeta_works = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5707 };
my $mymeta = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5702 };

my $has_test_requires = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.63_03 };

if (not $has_test_requires)
{
    %BUILD_DEPS = (%BUILD_DEPS, %TEST_DEPS);
    %TEST_DEPS = ();
}

my %extra_info = (
  resources => {
    repository => 'git://git.shadowcat.co.uk/gitmo/Moo.git',
    IRC => 'irc://irc.perl.org/#moose',
    bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Moo',
    license => 'http://dev.perl.org/licenses/',
  }
);

WriteMakefile(
  NAME => 'Moo',
  VERSION_FROM => 'lib/Moo.pm',
  CONFIGURE_REQUIRES => {
    'Dist::CheckConflicts' => '0.02',
  },
  PREREQ_PM => {
    %RUN_DEPS,
    ($] >= 5.010 ? () : ('MRO::Compat' => 0)),
    ($mymeta_works ? () : (%BUILD_DEPS)),
    'Dist::CheckConflicts' => '0.02',
  },
  ($mymeta_works
    ? ( # BUILD_REQUIRES makes MYMETA right, requires stops META being wrong
        BUILD_REQUIRES => \%BUILD_DEPS,
        $has_test_requires ? ( TEST_REQUIRES => \%TEST_DEPS ) : (),
        META_ADD => { requires => \%RUN_DEPS, %extra_info }
      )
    : ( # META_ADD both to get META right - only Makefile written
        META_ADD => {
          requires => \%RUN_DEPS,
          build_requires => \%BUILD_DEPS,
          test_requires => \%TEST_DEPS,
          %extra_info,
        }
      )
  ),
  META_MERGE => {
    no_index => {
      directory => [ 'xt' ]
    },
    x_breaks => {
      # enter conflicting data here, *and* in Moo::Conflicts
      'HTML::Restrict' => '2.1.5',
    },
  },
  ($mymeta && !$mymeta_works ? (NO_MYMETA => 1) : ()),
  LICENSE => 'perl',
  'EXE_FILES' => [
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

