use strict;
use warnings FATAL => 'all';
use 5.008003;
use ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

unless (-e 'META.yml') {
  warn "MYMETA.yml is going to be completely wrong. Sorry.\n";
}

my %BUILD_DEPS = (
  'Test::More' => 0.96,
  'Test::Fatal' => 0.003,
);

my %RUN_DEPS = (
  'Class::Method::Modifiers' => 1.05,
  'strictures' => 1.001001,
);

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $mymeta_works = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5707 };
my $mymeta = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5702 };

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
        META_ADD => { requires => \%RUN_DEPS }
      )
    : ( # META_ADD both to get META right - only Makefile written
        META_ADD => {
          requires => \%RUN_DEPS,
          build_requires => \%BUILD_DEPS,
        }
      )
  ),
  ($mymeta && !$mymeta_works ? (NO_MYMETA => 1) : ()),
  LICENSE => 'perl',
);
