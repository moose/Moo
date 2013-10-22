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
    package t::non_moo;

    sub new {
        my ($class, $arg) = @_;
        bless { attr => $arg }, $class;
    }

    sub attr { shift->{attr} }

    package t::ext_non_moo::with_attr;
    use Moo;
    extends qw( t::non_moo );

    has 'attr2' => ( is => 'ro' );

    sub BUILDARGS {
        my ( $class, @args ) = @_;
        shift @args if @args % 2 == 1;
        return { @args };
    }
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

    eval {
        $class->new( bar => 42, baz => 47, 'quux' );
    };
    like( $@, qr/You passed an odd number of arguments/,
        "new() requires a list or a HASH ref"
    );
}

my $non_moo = t::non_moo->new( 'bar' );
my $ext_non_moo = t::ext_non_moo::with_attr->new( 'bar', attr2 => 'baz' );

is $non_moo->attr, 'bar',
    "non-moo accepts params";
is $ext_non_moo->attr, 'bar',
    "extended non-moo passes params";
is $ext_non_moo->attr2, 'baz',
    "extended non-moo has own attributes";

{
  package NoAttr;
  use Moo;
}

eval {
  NoAttr->BUILDARGS( 37 );
};
like( $@, qr/Single parameters to new\(\) must be a HASH ref/,
  "default BUILDARGS requires a list or a HASH ref"
);
my $noattr = NoAttr->new({ foo => 'bar' });
is $noattr->{foo}, 'bar', 'without attributes, all params are stored';

done_testing;
