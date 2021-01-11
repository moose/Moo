use strict;
use warnings;

use Test::More;

# when using an Moose object and namespace::autoclean
# lazy attributes that get a value on initialize still
# have their builders run

{
    package MyMooseObject;
    use Moose;
}

{
    package BadObject;
    use Moo;
    # use MyMooseObject <- this is inferred here

    has attr => ( is => 'lazy' );
    sub _build_attr {2}

    # forces metaclass inflation like namespace::autoclean would
    BEGIN { __PACKAGE__->meta->name }
}

# use BadObject <- this is inferred here

is(
    BadObject->new( attr => 1 )->attr,
    1,
    q{namespace::autoclean doesn't run builders with default},
);

done_testing;
