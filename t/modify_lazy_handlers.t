use strictures 1;
use Test::More;
use lib qw(t/lib);

BEGIN { use_ok 'MooObjectWithDelegate' };

{
    package MooObjectWithDelegate;

    around 'connect', sub {
      my ($orig, $self, @args) = @_;
      return $self->$orig(@args) . 'c';
    };
}

ok my $moo_object = MooObjectWithDelegate->new,
  'got object';

is $moo_object->connect, 'abc',
  'got abc';

done_testing;
