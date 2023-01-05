use strict;
use warnings;
use lib 't/lib';

use Test::More;
use CaptureException;
use Moo::Object;

# See RT#84615

ok( Moo::Object->can('meta'), 'Moo::Object can meta');
is( exception { Moo::Object->meta->can('can') } , undef, "Moo::Object->meta->can doesn't explode" );

{
    package Example;
    use base 'Moo::Object';

}

ok( Example->can('meta'), 'Example can meta');
is( exception { Example->meta->can('can') } , undef, "Example->meta->can doesn't explode" );

# Haarg++ noting that previously, this *also* would have died due to its absence from %Moo::Makers;
{
    package Example_2;
    use Moo;

    has 'attr' => ( is => ro =>, );

    $INC{'Example_2.pm'} = 1;
}
{
    package Example_3;
    use base "Example_2";
}

ok( Example_2->can('meta'), 'Example_2 can meta') and do {
    return unless ok( Example_2->meta->can('get_all_attributes'), 'Example_2 meta can get_all_attributes' );
    my (@attributes) = Example_2->meta->get_all_attributes;
    is( scalar @attributes, 1, 'Has one attribute' );
};

ok( Example_3->can('meta'), 'Example_3 can meta') and do {
    return unless is( exception { Example_3->meta->can('can') } , undef, "Example_3->meta->can doesn't explode" );
    return unless ok( Example_3->meta->can('get_all_attributes'), 'Example_3 meta can get_all_attributes' );
    my (@attributes) = Example_3->meta->get_all_attributes;
    is( scalar @attributes, 1, 'Has one attribute' );
};

done_testing;
