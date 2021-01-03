use strict;
use warnings;

use Test::More;

{
    package NonMooClass::Strict;
    BEGIN { $INC{'NonMooClass/Strict.pm'} = __FILE__ }

    sub new {
        my ($class, $arg) = @_;
        die "invalid arguments: " . join(',', @_[2..$#_])
          if @_ > 2;
        bless { attr => $arg }, $class;
    }

    sub attr { shift->{attr} }

    package NonMooClass::Strict::MooExtend;
    use Moo;
    extends qw(NonMooClass::Strict);

    sub FOREIGNBUILDARGS {
        my ($class, %args) = @_;
        return $args{attr2};
    }

    package NonMooClass::Strict::MooExtendWithAttr;
    use Moo;
    extends qw(NonMooClass::Strict);

    has 'attr2' => ( is => 'ro' );

    sub FOREIGNBUILDARGS {
        my ($class, %args) = @_;
        return $args{attr};
    }
}


my $non_moo = NonMooClass::Strict->new( 'bar' );
my $ext_non_moo = NonMooClass::Strict::MooExtend->new( attr => 'bar', attr2 => 'baz' );
my $ext_non_moo2 = NonMooClass::Strict::MooExtendWithAttr->new( attr => 'bar', attr2 => 'baz' );

is $non_moo->attr, 'bar',
    "non-moo accepts params";
is $ext_non_moo->attr, 'baz',
    "extended non-moo passes params";
is $ext_non_moo2->attr, 'bar',
    "extended non-moo passes params";
is $ext_non_moo2->attr2, 'baz',
    "extended non-moo has own attributes";

done_testing;
