use strictures 1;
use Test::More;
use Test::Fatal;

BEGIN {
  package Role::For::Constructor;
  use Moo::Role;
  has extra_param => (is => 'ro');
}
BEGIN {
  package Some::Class;
  use Moo;
  BEGIN {
    my $con = Moo->_constructor_maker_for(__PACKAGE__);
    Moo::Role->apply_roles_to_object($con, 'Role::For::Constructor');
  }
}

{
  package Some::SubClass;
  use Moo;
  extends 'Some::Class';

  ::is(::exception {
    has bar => (is => 'ro');
  }, undef, 'extending constructor generator works');
}

done_testing;
