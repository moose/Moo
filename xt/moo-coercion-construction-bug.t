use strict;
use warnings;
use Test::More;

{
    package MyTest::Role;
    use Moo::Role;
    use Sub::Quote;

    has test_attr => (
        isa => quote_sub(q{ die $_[0] . "not an object" unless Scalar::Util::blessed($_[0]) }),
        coerce => quote_sub(q{
            return $_[0] if Scalar::Util::blessed($_[0]);
            die;
        }),
        is => 'ro',
        required => 1,
    );
}

{
    package MyTest::ClassOne;
    use Moo;

    with 'MyTest::Role';

}
{
    package MyTest::ClassTwo;
    use Moo;

    with 'MyTest::Role';
}

my $t = MyTest::ClassOne->new(test_attr => bless {}, 'Bar');
my $n = MyTest::ClassTwo->new( test_attr => $t);
is ref($n), 'MyTest::ClassTwo';

done_testing;

