package Class::Tiny::Object;

use strictures 1;

sub new {
  my $class = shift;
  bless({ @_ }, $class);
}

sub does {
  require Role::Tiny;
  { no warnings 'redefine'; *does = \&Role::Tiny::does_role }
  goto &Role::Tiny::does_role;
}

1;
