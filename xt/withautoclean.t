use Moo::_strictures;
use lib "t/lib";
use Test::More;
use InlineModule (
  'withautoclean::Class' => q{
    package withautoclean::Class;
    use Moo;

    with 'withautoclean::Role';

    before _clear_ctx => sub {};

    1;
  },
  'withautoclean::Role' => q{
    package withautoclean::Role;
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
  },
);

use_ok 'withautoclean::Class';

my $o = withautoclean::Class->new(_ctx => 1);
$o->_clear_ctx;
is $o->_ctx, undef, 'modified method works';

done_testing;
