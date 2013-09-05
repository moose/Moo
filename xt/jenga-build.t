use strictures;
use Test::More;
use Test::Fatal;

for my $stack (
  [qw(Moo Moose Moo)],
  [qw(Moose Moo Moose)],
  [qw(Mouse Moo Moose)],
) {
  for my $immut ( 0, 1 ) {
    for my $withattr ( 0, 1 ) {
      my $last_class;
      for my $level ( 0..$#$stack ) {
        my $class = join('::',
          'Stack',
          @{$stack}[0..$level],
          $withattr?'WithAttr':(),
          $immut?'Immut':(),
        );
        my $code
          = "package $class;\n"
          . "use $stack->[$level];\n"
          . ($last_class ? "extends '$last_class';\n" : '')
          . (!$level ?
              'has builder_count => ( is => "ro", default => sub { ($_[0]->builder_count||0) + 1 } );'."\n"
              .'has extend_count => ( is => "ro", default => sub { ($_[0]->extend_count||0) + 1 } );'."\n"
              .'has build_count => ( is => "rw", default => 0 );'."\n"
              .'sub BUILD { $_[0]->build_count($_[0]->build_count + 1) }'."\n"
            :
            $withattr ?
              "has attr$level => (is => 'ro');\n"
            : '')
        ;
        eval $code;
        die "$@\nwhile evaling:\n$code" if $@;
        if ($level && $withattr) {
          eval
            "package $class;\n"
            ."has '+extend_count' => (is => 'rw');\n";
          is $@, '', "extending attribute when stacking $class";
        }
        if ($immut) {
          $class->meta->make_immutable;
        }

        is exception {
          my $obj = $class->new;
          is $obj->builder_count, 1, "$class: attribute builder called once";
          is $obj->extend_count, 1, "$class: extended attribute builder called once";
          is $obj->build_count, 1, "$class: BUILD called once";
        }, undef, "$class: functions without errors";

        $last_class = $class;
      }
    }
  }
}

done_testing;
