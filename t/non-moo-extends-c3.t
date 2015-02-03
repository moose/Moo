use strict;
use warnings;
use Test::More;
use Moo ();

{
    package Foo;

    use mro 'c3';

    sub new {
        my ($class, $rest) = @_;
        return bless {%$rest}, $class;
    }
}

{
    package Foo::AddCD;

    use base 'Foo';

    sub new {
        my ($class, $rest) = @_;
        $rest->{c} = 'd';
        return $class->next::method($rest);
    }
}

{
    package Foo::AddEF;

    use base 'Foo';

    sub new {
        my ($class, $rest) = @_;
        $rest->{e} = 'f';
        return $class->next::method($rest);
    }
}

{
    package Foo::Parent;

    use Moo;
    use mro 'c3';
    extends 'Foo::AddCD', 'Foo';
}

{
    package Foo::Parent::Child;

    use Moo;
    use mro 'c3';
    extends 'Foo::AddEF', 'Foo::Parent';
}

my $foo = Foo::Parent::Child->new({a => 'b'});
ok exists($foo->{a}) && $foo->{a} eq 'b', 'has basic attrs';
ok exists($foo->{c}) && $foo->{c} eq 'd', 'AddCD works';
ok exists($foo->{e}) && $foo->{e} eq 'f', 'AddEF works';

done_testing;
