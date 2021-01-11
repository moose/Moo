use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
  package withautoclean::Role;
  use Moo::Role;

  use Moose ();
  # triggering metaclass inflation previously would cause Moo to cache the
  # method list. methods added later would not be composed properly.
  # this could be caused by namespace::autoclean
  BEGIN { Class::MOP::class_of(__PACKAGE__)->name }

  has _ctx => (
    is => 'ro',
    default => sub { },
    clearer => '_clear_ctx',
  );
}

is exception {
  package withautoclean::Class;
  use Moo;

  with 'withautoclean::Role';

  before _clear_ctx => sub {};

  1;
}, undef, 'clearer properly composed';

my $o = withautoclean::Class->new(_ctx => 1);
$o->_clear_ctx;
is $o->_ctx, undef, 'modified method works';

done_testing;
