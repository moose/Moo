#! perl

use Test::More;


{
    package R1;
    use Moo::Role;

    has attr => ( is => 'ro', default => sub { __PACKAGE__ } );
}


{
    package R2;
    use Moo::Role;

    has attr => ( is => 'ro', default => sub { __PACKAGE__ });
}

{
    package A1;
    use Moo;

    has attr => ( is => 'ro', default => sub { __PACKAGE__ });

    with 'R1';
    with 'R2';
}

is( A1->new->attr, 'A1', "don't override existing attribute in consumer" );

{
    package A2;
    use Moo;

    with 'R1';
    with 'R2';
}

is( A2->new->attr, 'R1', "don't override existing attribute in first role" );

{
    package A3;
    use Moo;

    use Test::More;
    use Test::Fatal;

    like ( exception { with 'R1', 'R2' },
	   qr/method name conflict/,
	   "complain if composer doesn't have attr and roles have duplicate attrs"
	 );
}

done_testing;
