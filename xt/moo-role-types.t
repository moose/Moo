use strict;
use warnings;
use lib 't/lib';

use Test::More;
use CaptureException;

{
    package TestClientClass;
    use Moo;

    sub consume {}
}

{
    package TestBadClientClass;
    use Moo;

    sub not_consume {}
}

{
    package TestRole;
    use Moo::Role;
    use Sub::Quote;

    has output_to => (
        isa => quote_sub(q{
            use Scalar::Util ();
            die $_[0] . "Does not have a ->consume method" unless Scalar::Util::blessed($_[0]) && $_[0]->can('consume'); }),
        is => 'ro',
        required => 1,
        coerce => quote_sub(q{
            use Scalar::Util ();
            if (Scalar::Util::blessed($_[0]) && $_[0]->can('consume')) {
              $_[0];
            } else {
              my %stuff = %{$_[0]};
              my $class = delete($stuff{class});
              $class->new(%stuff);
            }
        }),
    );
}

{
    package TestMooClass;
    use Moo;

    with 'TestRole';
}

{
    package TestMooseClass;
    use Moose;

    with 'TestRole';
}

foreach my $name (qw/ TestMooClass TestMooseClass /) {
    my $i = $name->new(output_to => TestClientClass->new());
    ok $i->output_to->can('consume');
    $i = $name->new(output_to => { class => 'TestClientClass' });
    ok $i->output_to->can('consume');
};

foreach my $name (qw/ TestMooClass TestMooseClass /) {
    ok !exception { TestBadClientClass->new };
    ok exception { $name->new(output_to => TestBadClientClass->new()) };
    ok exception { $name->new(output_to => { class => 'TestBadClientClass' }) };
}

done_testing;
