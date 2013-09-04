use strictures;
use Test::More;

for my $base (qw(Moo Moose)) {
  for my $immutable ( 0, 1 ) {
    my $type = $immutable ? 'Immut' : '';
    my $top = $base;
    my $middle = $base eq 'Moo' ? 'Moose' : 'Moo';
    my $basename = "${base}Base$type";
    my $middlename = "${middle}Middle$type";
    my $topname = "${top}Top$type";
    my ($basemake, $middlemake, $topmake) = $immutable ? ('','','')
      : map { "$_->meta->make_immutable" } ($basename, $middlename, $topname);

    eval <<"END_CODE" or die $@;
{
  package $basename;
  use $base;
  has build_count => ( is => 'rw', default => 0 );

  sub BUILD {
    \$_[0]->build_count(\$_[0]->build_count + 1);
  }
  $basemake
}
{
  package $middlename;
  use $middle;
  extends '$basename';
  has attr2 => (is => 'ro');
  $middlemake
}
{
  package $topname;
  use $top;
  extends '$middlename';
  has attr3 => (is => 'ro');
  $topmake
}
1;
END_CODE
  }
}

for my $type ('Moo', 'Moose') {
  for my $level ('Middle', 'Top') {
    for my $immut ('Immut', '') {
      my $class = $type.$level.$immut;
      my $obj = $class->new;
      is $obj->build_count, 1, "BUILD called once for $class";
    }
  }
}

done_testing;
