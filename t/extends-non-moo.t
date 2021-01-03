use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package NonMooClass;
    BEGIN { $INC{'NonMooClass.pm'} = __FILE__ }
    sub new {
        my ($proto, $args) = @_;
        bless $args, $proto;
    }

    sub to_app {
        (shift)->{app};
    }

    package NonMooClass::Child;
    BEGIN { $INC{'NonMooClass/Child.pm'} = __FILE__ }
    use base qw(NonMooClass);

    sub wrap {
        my($class, $app) = @_;
        $class->new({app => $app})
              ->to_app;
    }

    package NonMooClass::Child::MooExtend;
    use Moo;
    extends 'NonMooClass::Child';

    package NonMooClass::Child::MooExtendWithAttr;
    use Moo;
    extends 'NonMooClass::Child';
    has 'attr' => (is=>'ro');

    package NonMooClass::Child::MooExtendWithAttr::Extend;
    use Moo;
    extends 'NonMooClass::Child::MooExtendWithAttr';
    has 'attr2' => (is=>'ro');
}

ok my $app = 100,
  'prepared $app';

ok $app = NonMooClass::Child->wrap($app),
  '$app from $app';

is $app, 100,
  '$app still 100';

ok $app = NonMooClass::Child::MooExtend->wrap($app),
  '$app from $app';

is $app, 100,
  '$app still 100';

ok $app = NonMooClass::Child::MooExtendWithAttr->wrap($app),
  '$app from $app';

is $app, 100,
  '$app still 100';

ok $app = NonMooClass::Child::MooExtendWithAttr::Extend->wrap($app),
  '$app from $app';

is $app, 100,
  '$app still 100';

{
  package BadPrototype;
  BEGIN { $INC{'BadPrototype.pm'} = __FILE__ }
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

done_testing;
