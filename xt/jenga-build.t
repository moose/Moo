use strictures;
use Test::More;
use Test::Fatal;

my %stacked;
for my $stack (
  [qw(Moo Moose Moo)],
  [qw(Moose Moo Moose)],
  [qw(Mouse Moo Moose)],
  [qw(Perl Moo Moose)],
  [qw(Perl Moo Perl Moo)],
  [qw(Class::Tiny Moo Moose)],
  [qw(Class::Tiny Perl Moo Moose)],
) {
  for my $immut ( 0, 1 ) {
    for my $withattr ( 0, 1 ) {
      my $last_class;
      for my $level ( 0..$#$stack ) {
        my $class = join('::',
          'Stack',
          (map { my $s = $_; $s =~ s/:://g; $s } @{$stack}[0..$level]),
          $withattr?'WithAttr':(),
          $immut?'Immut':(),
        );
        if ($stacked{$class}++) {
          $last_class = $class;
          next;
        }
        (my $file = "$class.pm") =~ s{::}{/}g;
        my $type = $stack->[$level];
        my $code = "package $class;\n";
        $code .= "\$INC{'$file'} = '(generated)';\n";
        if ($type eq 'Perl') {
          $code .= $last_class
            ? "our \@ISA = ('$last_class');\n"
            : 'sub new { bless { ref $_[1] ? %{$_[1]} : @_[1..$#_] }, $_[0] }'."\n";
        }
        else {
          $code .= "use $type;\n";
          $code .= "extends '$last_class';\n"
            if $last_class;
        }

        if ($type !~ /^Mo/ ) {
          # no attr
        }
        elsif (grep { /^Mo/ } @{$stack}[0..$level-1]) {
          if ($withattr) {
            $code
              .= "has attr$level => (is => 'ro');\n"
              .  "eval { has '+extend_count' => (is => 'rw'); };\n"
              .  "::is(\$@, '', 'extending attribute when stacking $class');\n";
          }
        }
        else {
          $code .= '
            has builder_count => ( is => "ro", default => sub { ++$_[0]->{_builder_count} } );
            has extend_count => ( is => "ro", default => sub { ++$_[0]->{_extend_count} } );
            has initialized_at_build => ( is => "ro" );
            has build_count => ( is => "ro", default => 0 );
            sub BUILD {
              $_[0]->{initialized_at_build} = defined $_[0]->{build_count}
                if !exists $_[0]->{initialized_at_build};
              $_[0]->{build_count}++;
            }
          ';
        }

        eval $code;
        die "$@\nwhile evaling:\n$code" if $@;
        $last_class = $class;

        if ($immut) {
          next
            if ! grep { /Mo.se/ } @{$stack}[0..$level];
          $class->meta->make_immutable;
        }

        next
          unless $class->can('builder_count');

        is exception {
          my $obj = $class->new;
          ok $obj->{initialized_at_build}, "$class: attributes initialized when BUILD called";
          is $obj->builder_count, 1, "$class: attribute builder called once";
          is $obj->extend_count, 1, "$class: extended attribute builder called once";
          is $obj->build_count, 1, "$class: BUILD called once";
        }, undef, "$class: functions without errors";
      }
    }
  }
}

done_testing;
