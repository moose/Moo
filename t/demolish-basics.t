use strict;
use warnings;
use lib 't/lib';

use Test::More;
use CaptureException;

our @demolished;
package Foo;
use Moo;

sub DEMOLISH {
    my $self = shift;
    push @::demolished, __PACKAGE__;
}

package Foo::Sub;
use Moo;
extends 'Foo';

sub DEMOLISH {
    my $self = shift;
    push @::demolished, __PACKAGE__;
}

package Foo::Sub::Sub;
use Moo;
extends 'Foo::Sub';

sub DEMOLISH {
    my $self = shift;
    push @::demolished, __PACKAGE__;
}

package main;
{
    my $foo = Foo->new;
}
is_deeply(\@demolished, ['Foo'], "Foo demolished properly");
@demolished = ();
{
    my $foo_sub = Foo::Sub->new;
}
is_deeply(\@demolished, ['Foo::Sub', 'Foo'], "Foo::Sub demolished properly");
@demolished = ();
{
    my $foo_sub_sub = Foo::Sub::Sub->new;
}
is_deeply(\@demolished, ['Foo::Sub::Sub', 'Foo::Sub', 'Foo'],
          "Foo::Sub::Sub demolished properly");
@demolished = ();

done_testing;
