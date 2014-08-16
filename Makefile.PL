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
        'CPAN::Meta::Requirements' => 0,
      },
    },
    runtime => {
      requires => {
        'Class::Method::Modifiers'  => 1.10,  # for RT#80194
        'strictures'                => 1.004003,
        'Module::Runtime'           => 0.014, # for RT#86394
        'Role::Tiny'                => 1.003003,
        'Devel::GlobalDestruction'  => 0.11,  # for RT#78617
        'Import::Into'              => 1.002,
        'Scalar::Util'              => 0,
        'perl'                      => 5.006,
      },
      recommends => {
        'Class::XSAccessor'         => 1.18,
        'Sub::Name'                 => 0,
      },
    },
    develop   => {
      requires => { map { $_ => 0 } qw(
        indirect multidimensional bareword::filehandles
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
  x_breaks => { # add these entries to t/zzz-check-breaks.t
    'HTML::Restrict' => '== 2.1.5',
  },
  x_authority => 'cpan:MSTROUT',
);

my %MM_ARGS = (
  PREREQ_PM => {
    ($] >= 5.008 ? () : ('Task::Weaken' => 0)),
    ($] >= 5.010 ? () : ('MRO::Compat' => 0)),
  },
  realclean => { FILES => 'Distar/' },
);

##############################################################################
require ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

($MM_ARGS{NAME} = $META{name}) =~ s/-/::/g;
($MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm") =~ s{::}{/}g;
$MM_ARGS{LICENSE} = $META{license}
  if $eumm_version >= 6.30;
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
