use strictures 1;
use lib 'lib';
no warnings 'once'; # work around 5.6.2

{
    package Foo;
    use Moo;

    sub DEMOLISH {
        my $self = shift;
        my ($igd) = @_;

        print $igd ? "true" : "false", "\n";
    }
}

our $foo = Foo->new;
