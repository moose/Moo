#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'once'; # work around 5.6.2

{
    package Foo;
    use Moo;

    sub DEMOLISH {
        my $self = shift;
        my ($igd) = @_;

        print $igd || 0, "\n";
    }
}

our $foo = Foo->new;
