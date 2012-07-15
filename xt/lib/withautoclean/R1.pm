package withautoclean::R1;
use Moo::Role;

# Doing this (or loading a class which is built with Moose)
# and then loading autoclean - everything breaks...
use Moose ();
use namespace::autoclean;
# Wouldn't happen normally, but is likely to as you part-port something.

has _ctx => (
    is => 'ro',
    default => sub {
    },
    clearer => '_clear_ctx',
);

1;

