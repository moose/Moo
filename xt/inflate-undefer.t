use strict;
use warnings;

use Test::More;

use Moose ();

{
  package MyClass;
  use Moo;
  use Sub::Defer qw(defer_sub);

  my $undeferred;
  my $deferred = defer_sub +__PACKAGE__.'::welp' => sub {
    $undeferred = sub { 1 };
  };

  __PACKAGE__->meta->name;

  ::ok +$undeferred, "meta inflation undefers subs";
  ::is +__PACKAGE__->can('welp'), $undeferred, "undeferred sub installed";
}

done_testing;
