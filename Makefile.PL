use strict;
use warnings FATAL => 'all';
use 5.006;

my %META = (
  name => 'Moo',
  license => 'perl_5',
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker'   => 0,
    } },
    build => { requires => {
    } },
    test => {
      requires => {
        'Test::More'  => 0.94,
        'Test::Fatal' => 0.003,
      },
      recommends => {
        'CPAN::Meta' => 0,
        'CPAN::Meta::Requirements' => 0,
      },
    },
    runtime => {
      requires => {
        'Class::Method::Modifiers'  => 1.10,  # for RT#80194
        'Module::Runtime'           => 0.014, # for RT#86394
        'Role::Tiny'                => 2,
        'Devel::GlobalDestruction'  => 0.11,  # for RT#78617
        'Scalar::Util'              => 0,
        'perl'                      => 5.006,
        'Exporter'                  => 5.57,  # Import 'import'
      },
      recommends => {
        'Class::XSAccessor'         => 1.18,
        'Sub::Name'                 => 0.08,
        'strictures'                => 2,
      },
    },
    develop   => {
      requires => {
        'strictures' => 2,
        'indirect' => 0,
        'multidimensional' => 0,
        'bareword::filehandles' => 0,
        'Moose' => 0,
        'Mouse' => 0,
        'namespace::clean' => 0,
        'namespace::autoclean' => 0,
        'MooseX::Types::Common::Numeric' => 0,
        'Type::Tiny' => 0,
        'Class::Tiny' => 1.001,
      },
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
  x_breaks => {
    'HTML::Restrict'            => '== 2.1.5',
    'MySQL::Workbench::Parser'  => '<= 0.05',
    'MooX::Emulate::Class::Accessor::Fast' => '<= 0.02',
    'WebService::Shutterstock'  => '<= 0.006',
    'File::DataClass'           => '<= 0.54.1',
    'App::Commando'             => '<= 0.012',
  },
  x_authority => 'cpan:MSTROUT',
  x_cpants => { ignore => {
    use_strict => 'internal module used to apply strict',
    use_warnings => 'internal module used to apply warnings',
  } },
);

my %MM_ARGS = (
  PREREQ_PM => {
    ($] >= 5.008 ? () : ('Task::Weaken' => 0)),
    ($] >= 5.010 ? () : ('MRO::Compat' => 0)),
  },
);

{
  package MY;
  !-f 'META.yml' and $^O ne 'MSWin32' and eval q{
    sub test_via_harness {
      my($self, $perl, $tests) = @_;
      return $self->SUPER::test_via_harness("MOO_FATAL_WARNINGS=1 $perl", $tests);
    }
  };

  sub postamble {
    <<"POSTAMBLE";
fulltest: test
\tMOO_XS_DISABLE=1 \$(MAKE) test
POSTAMBLE
  }
}

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

($MM_ARGS{NAME} = $META{name}) =~ s/-/::/g;
($MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm") =~ s{::}{/}g;
$META{license} = [ $META{license} ]
  if $META{license} && !ref $META{license};
$MM_ARGS{LICENSE} = $META{license}[0]
  if $META{license} && $eumm_version >= 6.30;
$MM_ARGS{NO_MYMETA} = 1
  if $mymeta_broken;
$MM_ARGS{META_ADD} = { 'meta-spec' => { version => 2 }, %META }
  unless -f 'META.yml';

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  my $r = $MM_ARGS{$key} = {
    %{$META{prereqs}{$_}{requires} || {}},
    %{delete $MM_ARGS{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

$MM_ARGS{MIN_PERL_VERSION} = delete $MM_ARGS{PREREQ_PM}{perl} || 0;

delete $MM_ARGS{MIN_PERL_VERSION}
  if $eumm_version < 6.47_01;
$MM_ARGS{BUILD_REQUIRES} = {%{$MM_ARGS{BUILD_REQUIRES}}, %{delete $MM_ARGS{TEST_REQUIRES}}}
  if $eumm_version < 6.63_03;
$MM_ARGS{PREREQ_PM} = {%{$MM_ARGS{PREREQ_PM}}, %{delete $MM_ARGS{BUILD_REQUIRES}}}
  if $eumm_version < 6.55_01;
delete $MM_ARGS{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

ExtUtils::MakeMaker::WriteMakefile(%MM_ARGS);
## END BOILERPLATE ###########################################################
