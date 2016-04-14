use Moo::_strictures;
use Test::More;
use Carp qw(croak);
no Moo::sification;
use lib 't/lib';
use ErrorLocation;

location_ok <<'END_CODE', 'Moo::_Util::_load_module';
use Moo::_Utils qw(_load_module);
_load_module("This::Module::Does::Not::Exist::". int rand 50000);
END_CODE

location_ok <<'END_CODE', 'Sub::Defer::defer_sub - unqualified name';
use Sub::Defer qw(defer_sub);
defer_sub 'welp' => sub { sub { 1 } };
END_CODE

location_ok <<'END_CODE', 'Sub::Defer::defer_sub - unqualified name in Moo class';
use Moo;
use Sub::Defer qw(defer_sub);
defer_sub 'welp' => sub { sub { 1 } };
END_CODE

location_ok <<'END_CODE', 'Sub::Quote::quote_sub - long package';
use Sub::Quote qw(quote_sub);
quote_sub +("x" x 500).'::x', '1';
END_CODE

location_ok <<'END_CODE', 'Sub::Quote::unquote_sub - bad captures';
use Sub::Quote qw(unquote_sub quote_sub);
unquote_sub quote_sub '1', { '&foo' => sub { 1 } };
END_CODE

location_ok <<'END_CODE', 'Sub::Quote::unquote_sub - compile error';
use Sub::Quote qw(unquote_sub quote_sub);
unquote_sub quote_sub ' { ] } ';
END_CODE

location_ok <<'END_CODE', 'Moo - import into role';
use Moo::Role;
use Moo ();
Moo->import;
END_CODE

location_ok <<'END_CODE', 'Moo::has - unbalanced options';
use Moo;
has arf => (is => 'ro', 'garf');
END_CODE

location_ok <<'END_CODE', 'Moo::extends - extending a role';
BEGIN {
  eval qq{
    package ${PACKAGE}::Role;
    use Moo::Role;
    1;
  } or die $@;
}

use Moo;
extends "${PACKAGE}::Role";
END_CODE

location_ok <<'END_CODE', 'Method::Generate::Accessor - missing is';
use Moo;
has 'attr';
END_CODE

location_ok <<'END_CODE', 'Method::Generate::Accessor - reader extra params';
use Moo;
has 'attr' => (is => 'rwp', lazy => 1, default => 1);
my $o = $PACKAGE->new;
package Elsewhere;
$o->attr(5);
END_CODE

location_ok <<'END_CODE', 'Method::Generate::Accessor - overwrite method';
use Moo;
sub attr { 1 }
has 'attr' => (is => 'ro');
END_CODE

location_ok <<'END_CODE', 'Method::Generate::Accessor - asserter with unset';
use Moo;
has 'attr' => (is => 'ro', asserter => 'assert_attr');
my $o = $PACKAGE->new;
package Elsewhere;
$o->assert_attr;
END_CODE

location_ok <<'END_CODE', 'Method::Generate::Accessor - invalid default';
use Moo;
sub attr { 1 }
has 'attr' => (is => 'ro', default => []);
END_CODE

location_ok <<'END_CODE', 'Method::Generate::Constructor - +attr without attr';
use Moo;
has 'attr' => (is => 'ro');
has 'attr' => (default => 1);
END_CODE

location_ok <<'END_CODE', 'Method::Generate::Constructor - modifying @ISA unexpectedly';
BEGIN {
  eval qq{
    package ${PACKAGE}::Parent$_;
    use Moo;
    has attr$_ => (is => 'ro');
    __PACKAGE__->new;
    1;
  } or die $@
    for (1, 2);
}

use Moo;
extends "${PACKAGE}::Parent1";
has attr3 => (is => 'ro');
our @ISA = "${PACKAGE}::Parent2";
package Elsewhere;
$PACKAGE->new;
END_CODE

location_ok <<'END_CODE', 'Method::Generate::Constructor - existing constructor';
use Moo;
sub new { }
has attr => (is => 'ro');
END_CODE

location_ok <<'END_CODE', 'Method::Generate::Constructor - BUILDARGS output';
use Moo;
sub BUILDARGS { 1 }
has attr => (is => 'ro');
package Elsewhere;
$PACKAGE->new;
END_CODE

location_ok <<'END_CODE', 'Method::Generate::Constructor - inlined BUILDARGS output';
use Moo;
has attr => (is => 'ro');
package Elsewhere;
$PACKAGE->new(5);
END_CODE

location_ok <<'END_CODE', 'Method::Generate::Constructor - inlined BUILDARGS output (wrapped)';
use Moo;
has attr => (is => 'ro');
sub wrap_new {
  my $class = shift;
  $class->new(@_);
}
package Elsewhere;
$PACKAGE->wrap_new(5);
END_CODE

location_ok <<'END_CODE', 'Method::Generate::Constructor - required attributes';
use Moo;
has attr => (is => 'ro', required => 1);
package Elsewhere;
$PACKAGE->new;
END_CODE

location_ok <<'END_CODE', 'Moo::HandleMoose::FakeMetaClass - class method call';
require Moo::HandleMoose::FakeMetaClass;
Moo::HandleMoose::FakeMetaClass->guff;
END_CODE

location_ok <<'END_CODE', 'Moo::Object - new args';
use Moo::Object;
our @ISA = 'Moo::Object';
package Elsewhere;
$PACKAGE->new(5);
END_CODE

location_ok <<'END_CODE', 'Moo::Role - import into class';
use Moo;
use Moo::Role ();
Moo::Role->import;
END_CODE

location_ok <<'END_CODE', 'Moo::Role::has - unbalanced options';
use Moo::Role;
has arf => (is => 'ro', 'garf');
END_CODE

location_ok <<'END_CODE', 'Moo::Role::methods_provided_by - not a role';
BEGIN {
  eval qq{
    package ${PACKAGE}::Class;
    use Moo;
    1;
  } or die $@;
}

use Moo;
has arf => (is => 'ro', handles => "${PACKAGE}::Class");
END_CODE

location_ok <<'END_CODE', 'Moo::Role::apply_roles_to_package - not a module';
use Moo;
with {};
END_CODE

location_ok <<'END_CODE', 'Moo::Role::apply_roles_to_package - not a role';
BEGIN {
  eval qq{
    package ${PACKAGE}::Class;
    use Moo;
    1;
  } or die $@;
}

use Moo;
with "${PACKAGE}::Class";
END_CODE

location_ok <<'END_CODE', 'Moo::Role::apply_single_role_to_package - not a role';
BEGIN {
  eval qq{
    package ${PACKAGE}::Class;
    use Moo;
    1;
  } or die $@;
}

use Moo;
use Moo::Role ();
Moo::Role->apply_single_role_to_package($PACKAGE, "${PACKAGE}::Class");
END_CODE

location_ok <<'END_CODE', 'Moo::Role::create_class_with_roles - not a role';
BEGIN {
  eval qq{
    package ${PACKAGE}::Class;
    use Moo;
    1;
  } or die $@;
}

use Moo;
use Moo::Role ();
Moo::Role->create_class_with_roles($PACKAGE, "${PACKAGE}::Class");
END_CODE

location_ok <<'END_CODE', 'Moo::HandleMoose::inject_all - Moo::sification disabled';
use Moo::HandleMoose ();
Moo::HandleMoose->import;
END_CODE

done_testing;
