use strict;
use warnings;
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
    use namespace::autoclean;

    has attr => ( is => 'lazy' );
    sub _build_attr {2}
}

use Test::More;
# use BadObject <- this is inferred here

is(
    BadObject->new( attr => 1 )->attr,
    1,
    q{namespace::autoclean doesn't run builders with default},
);

done_testing;
