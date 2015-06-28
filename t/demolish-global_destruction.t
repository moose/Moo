use Moo::_strictures;
no warnings 'once';
use POSIX ();

$| = 1;

our $fail = 2;
our $tests = 0;
sub ok {
  my ($ok, $message) = @_;
  print
    +($ok ? '' : 'not ')
    . 'ok ' . ++$tests
    . ($message ? " - $message" : '')
    . "\n";
  return $ok;
}

print "1..2\n";

BEGIN {
    package Foo;
    use Moo;

    sub DEMOLISH {
        my $self = shift;
        my ($igd) = @_;
        ::ok(
            !$igd,
            'in_global_destruction state is passed to DEMOLISH properly (false)'
        ) and $fail-- ;
    }
}

{
    my $foo = Foo->new;
}

END { $? = $fail }

BEGIN {
    package Bar;
    use Moo;

    sub DEMOLISH {
        my $self = shift;
        my ($igd) = @_;

        ::ok(
            $igd,
            'in_global_destruction state is passed to DEMOLISH properly (true)'
        ) and $fail--;
        POSIX::_exit($fail);
    }
}

our $bar = Bar->new;
