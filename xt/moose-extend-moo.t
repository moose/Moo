use strict;
use warnings;


{
    package Parent;
    use Moo;
    has message => ( is => 'ro', required => 1 ),
}

{
    package Child;
    use Moose;
    extends 'Parent';
    use Moose::Util::TypeConstraints;
    use namespace::clean;   # <-- essential
    has message => (
        is => 'ro', isa => 'Str',
        lazy => 1,
        default => sub { 'overridden message sub here' },
    );
}

my $obj = Child->new(message => 'custom message');

use Test::More;
is($obj->message, 'custom message', 'accessor works');

done_testing;

__END__

without namespace::clean, gives the (non-fatal) warning:
You are overwriting a locally defined function (message) with an accessor

...because Moose::Util::TypeConstraints exports a 'message' sub!
