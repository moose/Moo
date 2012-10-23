use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %BUILD_DEPS = (
  'Test::More' => 0.96,
  'Test::Fatal' => 0.003,
);

my %RUN_DEPS = (
  'Class::Method::Modifiers' => 1.10,
  'strictures' => 1.001001,
  'Module::Runtime' => 0.012,
  'Role::Tiny' => 1.001003,
  'Devel::GlobalDestruction' => 0.09,
);

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $mymeta_works = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5707 };
my $mymeta = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5702 };

my %extra_info = (
  resources => {
    repository => 'git://git.shadowcat.co.uk/gitmo/Moo.git'
  }
);

WriteMakefile(
  NAME => 'Moo',
  VERSION_FROM => 'lib/Moo.pm',
  PREREQ_PM => {
    %RUN_DEPS,
    ($] >= 5.010 ? () : ('MRO::Compat' => 0)),
    ($mymeta_works ? () : (%BUILD_DEPS)),
  },
  ($mymeta_works
    ? ( # BUILD_REQUIRES makes MYMETA right, requires stops META being wrong
        BUILD_REQUIRES => \%BUILD_DEPS,
        META_ADD => { requires => \%RUN_DEPS, %extra_info }
      )
    : ( # META_ADD both to get META right - only Makefile written
        META_ADD => {
          requires => \%RUN_DEPS,
          build_requires => \%BUILD_DEPS,
          %extra_info,
        }
      )
  ),
  META_MERGE => {
    no_index => {
      directory => [ 'xt' ]
    }
  },
  ($mymeta && !$mymeta_works ? (NO_MYMETA => 1) : ()),
  LICENSE => 'perl',
);
