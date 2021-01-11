use strict;
use warnings;
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
        'Test::More'  => '0.94',
        'Test::Fatal' => '0.003',
      },
      recommends => {
        'Parse::CPAN::Meta'         => '1.4200',
        'CPAN::Meta::Requirements'  => 0,
      },
    },
    runtime => {
      requires => {
        'perl'                      => '5.006',
        'Scalar::Util'              => '1.00',
        'Exporter'                  => 0,
        'Carp'                      => 0,
        'Class::Method::Modifiers'  => '1.10',  # for RT#80194
        'Role::Tiny'                => '2.002003',
        'Sub::Quote'                => '2.006006',
        'Sub::Defer'                => '2.006006',
      },
      recommends => {
        'Class::XSAccessor'         => '1.18',
        'Sub::Util'                 => '0',
      },
    },
    develop => {
      requires => {
        'Class::Tiny'                     => '1.001',
        'Moose'                           => '1.15',
        'Mouse'                           => 0,
        'namespace::autoclean'            => 0,
        'namespace::clean'                => 0,
        'Type::Tiny'                      => '0.004',
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
    license => [ 'https://dev.perl.org/licenses/' ],
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
);

my $xt = $ENV{EXTENDED_TESTING};

my %MM_ARGS = (
  PREREQ_PM => {
    ("$]" < 5.014_000 ? ('Devel::GlobalDestruction' => '0.11') : ()),
  },
  ($xt ? (
    TEST_REQUIRES => {
      %{ $META{prereqs}{runtime}{recommends} },
      %{ $META{prereqs}{test}{recommends} },
      %{ $META{prereqs}{develop}{requires} },
    },
    test => { TESTS => 't/*.t xt/*.t' },
  ):()),
);

{
  package MY;

  sub test_via_harness {
    my($self, $perl, $tests) = @_;
    $perl .= ' -I'.$self->catdir('t','lib').' "-MTestEnv=$(MOO_TEST_ENV)"';
    return $self->SUPER::test_via_harness($perl, $tests);
  }

  sub postamble {
    my $MOO_TEST_ENV = (!-f 'META.yml' || $xt) ? "MOO_FATAL_WARNINGS" : '';
    ($xt ? <<"XT" : '')
test :: test_no_xs
XT
    .<<"POSTAMBLE"
MOO_TEST_ENV=$MOO_TEST_ENV
fulltest: test test_no_xs
\t\$(NOECHO) \$(NOOP)
test_no_xs: \$(TEST_TYPE)_no_xs
\t\$(NOECHO) \$(NOOP)
POSTAMBLE
    .join('', map <<"TEST_TYPE", 'dynamic', 'static', '')
test_${_}_no_xs: pure_all
\t\$(NOECHO)\$(MAKE) test_$_ MOO_TEST_ENV="\$(MOO_TEST_ENV),MOO_XS_DISABLE"
TEST_TYPE
  }
}

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

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
$MM_ARGS{PL_FILES} ||= {};
$MM_ARGS{NORECURS} = 1
  if not exists $MM_ARGS{NORECURS};

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
