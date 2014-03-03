use strictures 1;
use Test::More;
use Test::Fatal;

{
    package t::moo::extends_non_moo::base;

    sub new {
        my ($proto, $args) = @_;
        bless $args, $proto;
    }

    sub to_app {
        (shift)->{app};
    }

    package t::moo::extends_non_moo::middle;
    use base qw(t::moo::extends_non_moo::base);

    sub wrap {
        my($class, $app) = @_;
        $class->new({app => $app})
              ->to_app;
    }

    package t::moo::extends_non_moo::moo;
    use Moo;
    extends 't::moo::extends_non_moo::middle';

    package t::moo::extends_non_moo::moo_with_attr;
    use Moo;
    extends 't::moo::extends_non_moo::middle';
    has 'attr' => (is=>'ro');

    package t::moo::extends_non_moo::second_level_moo;
    use Moo;
    extends 't::moo::extends_non_moo::moo_with_attr';
    has 'attr2' => (is=>'ro');
}

ok my $app = 100,
  'prepared $app';

ok $app = t::moo::extends_non_moo::middle->wrap($app),
  '$app from $app';

is $app, 100,
  '$app still 100';

ok $app = t::moo::extends_non_moo::moo->wrap($app),
  '$app from $app';

is $app, 100,
  '$app still 100';

ok $app = t::moo::extends_non_moo::moo_with_attr->wrap($app),
  '$app from $app';

is $app, 100,
  '$app still 100';

ok $app = t::moo::extends_non_moo::second_level_moo->wrap($app),
  '$app from $app';

is $app, 100,
  '$app still 100';

{
  package BadPrototype;
  sub new () { bless {}, shift }
}
{
  package ExtendBadPrototype;
  use Moo;
  ::is(::exception {
    extends 'BadPrototype';
    has attr1 => (is => 'ro');
  }, undef, 'extending class with prototype on new');
}

done_testing();
