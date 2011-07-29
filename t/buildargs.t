use strictures 1;
use Test::More;

{
    package Qux;
    use Moo;

    has bar => ( is => "rw" );
    has baz => ( is => "rw" );

    package Quux;
    use Moo;

    extends qw(Qux);
}
{
    package Foo;
    use Moo;

    has bar => ( is => "rw" );
    has baz => ( is => "rw" );

    sub BUILDARGS {
        my ( $class, @args ) = @_;
        unshift @args, "bar" if @args % 2 == 1;
        return $class->SUPER::BUILDARGS(@args);
    }

    package Bar;
    use Moo;

    extends qw(Foo);
}

{
    package Baz;
    use Moo;

    has bar => ( is => "rw" );
    has baz => ( is => "rw" );

    around BUILDARGS => sub {
        my $orig = shift;
        my ( $class, @args ) = @_;

        unshift @args, "bar" if @args % 2 == 1;

        return $class->$orig(@args);
    };

    package Biff;
    use Moo;

    extends qw(Baz);
}

foreach my $class (qw(Foo Bar Baz Biff)) {
    is( $class->new->bar, undef, "no args" );
    is( $class->new( bar => 42 )->bar, 42, "normal args" );
    is( $class->new( 37 )->bar, 37, "single arg" );
    {
        my $o = $class->new(bar => 42, baz => 47);
        is($o->bar, 42, '... got the right bar');
        is($o->baz, 47, '... got the right baz');
    }
    {
        my $o = $class->new(42, baz => 47);
        is($o->bar, 42, '... got the right bar');
        is($o->baz, 47, '... got the right baz');
    }
}

foreach my $class (qw(Qux Quux)) {
    my $o = $class->new(bar => 42, baz => 47);
    is($o->bar, 42, '... got the right bar');
    is($o->baz, 47, '... got the right baz');

    eval {
        $class->new( 37 );
    };
    like( $@, qr/Single parameters to new\(\) must be a HASH ref/,
        "new() requires a list or a HASH ref"
    );

    eval {
        $class->new( [ 37 ] );
    };
    like( $@, qr/Single parameters to new\(\) must be a HASH ref/,
        "new() requires a list or a HASH ref"
    );
}

done_testing;

