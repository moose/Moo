
use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;


my $FilePath = sub { die "does not pass the type constraint" if $_[0] eq '/' };

{
    package Baz;
    use Moo;

    has 'path' => (
        is       => 'ro',
        isa      => $FilePath,
        required => 1,
    );

    sub BUILD {
        my ( $self, $params ) = @_;
        die $params->{path} . " does not exist"
            unless -e $params->{path};
    }

    # Defining this causes the FIRST call to Baz->new w/o param to fail,
    # if no call to ANY Moo::Object->new was done before.
    sub DEMOLISH {
        my ( $self ) = @_;
    }
}

{
    package Qee;
    use Moo;

    has 'path' => (
        is       => 'ro',
        isa      => $FilePath,
        required => 1,
    );

    sub BUILD {
        my ( $self, $params ) = @_;
        die $params->{path} . " does not exist"
            unless -e $params->{path};
    }

    # Defining this causes the FIRST call to Qee->new w/o param to fail...
    # if no call to ANY Moo::Object->new was done before.
    sub DEMOLISH {
        my ( $self ) = @_;
    }
}

{
    package Foo;
    use Moo;

    has 'path' => (
        is       => 'ro',
        isa      => $FilePath,
        required => 1,
    );

    sub BUILD {
        my ( $self, $params ) = @_;
        die $params->{path} . " does not exist"
            unless -e $params->{path};
    }

    # Having no DEMOLISH, everything works as expected...
}

check_em ( 'Baz' );     #     'Baz plain' will fail, aka NO error
check_em ( 'Qee' );     #     ok
check_em ( 'Foo' );     #     ok

check_em ( 'Qee' );     #     'Qee plain' will fail, aka NO error
check_em ( 'Baz' );     #     ok
check_em ( 'Foo' );     #     ok

check_em ( 'Foo' );     #     ok
check_em ( 'Baz' );     #     ok !
check_em ( 'Qee' );     #     ok


sub check_em {
     my ( $pkg ) = @_;
     my ( %param, $obj );

     # Uncomment to see, that it is really any first call.
     # Subsequents calls will not fail, aka giving the correct error.
     {
         local $@;
         my $obj = eval { $pkg->new; };
         ::like( $@, qr/Missing required argument/, "... $pkg plain" );
         ::is( $obj, undef, "... the object is undef" );
     }
     {
         local $@;
         my $obj = eval { $pkg->new(); };
         ::like( $@, qr/Missing required argument/, "... $pkg empty" );
         ::is( $obj, undef, "... the object is undef" );
     }
     {
         local $@;
         my $obj = eval { $pkg->new ( notanattr => 1 ); };
         ::like( $@, qr/Missing required argument/, "... $pkg undef" );
         ::is( $obj, undef, "... the object is undef" );
     }

     {
         local $@;
         my $obj = eval { $pkg->new ( %param ); };
         ::like( $@, qr/Missing required argument/, "... $pkg undef param" );
         ::is( $obj, undef, "... the object is undef" );
     }
     {
         local $@;
         my $obj = eval { $pkg->new ( path => '/' ); };
         ::like( $@, qr/does not pass the type constraint/, "... $pkg root path forbidden" );
         ::is( $obj, undef, "... the object is undef" );
     }
     {
         local $@;
         my $obj = eval { $pkg->new ( path => '/this_path/does/not_exist' ); };
         ::like( $@, qr/does not exist/, "... $pkg non existing path" );
         ::is( $obj, undef, "... the object is undef" );
     }
     {
         local $@;
         my $obj = eval { $pkg->new ( path => $FindBin::Bin ); };
         ::is( $@, '', "... $pkg no error" );
         ::isa_ok( $obj, $pkg );
         ::isa_ok( $obj, 'Moo::Object' );
         ::is( $obj->path, $FindBin::Bin, "... $pkg got the right value" );
     }
}

done_testing;
