use strictures 1;
use Test::More;

{
    package t::non_moo_strict;

    sub new {
        my ($class, $arg) = @_;
        die "invalid arguments: " . join(',', @_[2..$#_])
          if @_ > 2;
        bless { attr => $arg }, $class;
    }

    sub attr { shift->{attr} }

    package t::ext_non_moo_strict::with_attr;
    use Moo;
    extends qw( t::non_moo_strict );

    has 'attr2' => ( is => 'ro' );

    sub FOREIGNBUILDARGS {
        my ($class, %args) = @_;
        return $args{attr};
    }

    package t::ext_non_moo_strict::without_attr;
    use Moo;
    extends qw( t::non_moo_strict );

    sub FOREIGNBUILDARGS {
        my ($class, %args) = @_;
        return $args{attr2};
    }
}


my $non_moo = t::non_moo_strict->new( 'bar' );
my $ext_non_moo = t::ext_non_moo_strict::with_attr->new( attr => 'bar', attr2 => 'baz' );
my $ext_non_moo2 = t::ext_non_moo_strict::without_attr->new( attr => 'bar', attr2 => 'baz' );

is $non_moo->attr, 'bar',
    "non-moo accepts params";
is $ext_non_moo->attr, 'bar',
    "extended non-moo passes params";
is $ext_non_moo->attr2, 'baz',
    "extended non-moo has own attributes";
is $ext_non_moo2->attr, 'baz',
    "extended non-moo passes params";


done_testing;

