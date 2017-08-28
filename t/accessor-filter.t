use Moo::_strictures;
use Test::More;
use Test::Fatal;

my %expects = (
    1 => {
        class => "MyClass1",
        in    => 1,
    },
    2 => {
        class => "MyClass2",
        in    => 2,
        out   => 6.28,
    },
    3 => {
        class => "MyClass3",
        in    => 3,
        out   => "COERCED into string from 3",
    },
    4 => {
        class   => "MyClass4",
        in      => 4,
        out     => "Converted into string from 4",
        initial => undef,
    },
    5 => {
        class   => "MyClass5",
        in      => 5,
        out     => "Converted into string from 5",
        initial => 123,
    },
);

sub run_for {
    my $classN = shift;

    my $exp   = $expects{$classN};
    my $class = $exp->{class};

    my $obj = $class->new;

    if ( $obj->can('prepare') ) {
        $obj->prepare;
    }

    if ( $exp->{initial} ) {
        is $obj->attr, $exp->{initial}, "Initial value";
    }

    my $n = $exp->{in};

    $obj->attr($n);

    is $obj->attr, ( exists $exp->{out} ? $exp->{out} : $n ), "after filter";
}

{

    package MyClass1;
    use Moo;

    has attr => (
        is      => 'rw',
        builder => sub { return 3.1415926; },
        filter =>
          sub { print "  filter(", join( ", ", @_ ), ")\n"; return $_[1]; },
    );
}

{

    package MyClass2;
    use Moo;

    has multiplier => ( is => 'rw', default => 3.14, );

    has attr => (
        is     => 'rw',
        filter => 1,
    );

    sub _filter_attr {
        my $this = shift;
        my $val  = shift;
        return $val * $this->multiplier;
    }
}

{

    package MyClass3;
    use Moo;

    has attr => (
        is         => 'rw',
        unknownOne => "YES!",
        filter     => 'commonFilter',
    );

    sub commonFilter {
        print "  commonFilter(", join( ", ", @_ ), ")\n";
        return "COERCED into string from $_[1]";
    }
}

{

    package MyClass4;
    use Moo;

    has attr => (
        is         => 'rw',
        lazy       => 1,
        predicate  => 1,
        unknownOne => "YES!",
        filter     => 'commonFilter',
    );

    sub commonFilter {
        my $this = shift;
        my $val  = shift;
        print "  NOW:", $this->attr, "\n" if $this->has_attr;
        return "Converted into string from $val";
    }
}

{

    package MyClass5;
    use Moo;

    has attr => (
        is         => 'rw',
        lazy       => 1,
        predicate  => 1,
        default    => 123,
        unknownOne => "YES!",
        filter     => 'commonFilter',
    );

    sub commonFilter {
        my $this = shift;
        my $val  = shift;
        print "  NOW:", $this->attr if $this->has_attr, "\n";
        return "Converted into string from $val";
    }

    sub prepare {
        $_[0]->attr;
    }
}

run_for($_) for 1 .. 5;

done_testing();
