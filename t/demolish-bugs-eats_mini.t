
use strictures 1;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moo;

    has 'bar' => (
        is       => 'ro',
        required => 1,
    );

    # Defining this causes the FIRST call to Baz->new w/o param to fail,
    # if no call to ANY Moo::Object->new was done before.
    sub DEMOLISH {
        my ( $self ) = @_;
        # ... Moo (kinda) eats exceptions in DESTROY/DEMOLISH";
    }
}

{
    my $obj = eval { Foo->new; };
    like( $@, qr/Missing required arguments/, "... Foo plain" );
    is( $obj, undef, "... the object is undef" );
}

{
    package Bar;

    sub new { die "Bar died"; }

    sub DESTROY {
        die "Vanilla Perl eats exceptions in DESTROY too";
    }
}

{
    my $obj = eval { Bar->new; };
    like( $@, qr/Bar died/, "... Bar plain" );
    is( $obj, undef, "... the object is undef" );
}

{
    package Baz;
    use Moo;

    sub DEMOLISH {
        $? = 0;
    }
}

{
    local $@ = 42;
    local $? = 84;

    {
        Baz->new;
    }

    is( $@, 42, '$@ is still 42 after object is demolished without dying' );
    is( $?, 84, '$? is still 84 after object is demolished without dying' );

    local $@ = 0;

    {
        Baz->new;
    }

    is( $@, 0, '$@ is still 0 after object is demolished without dying' );

}

done_testing;
