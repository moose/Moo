use Moo::_strictures;
use Test::More;
use Test::Fatal;

{
  package RollyRole;

  use Moo::Role;

  has f => (is => 'ro', default => sub { 0 });
}

{
  package ClassyClass;

  use Moo;

  has f => (is => 'ro', default => sub { 1 });
}

{
  package UsesTheRole;

  use Moo;

  with 'RollyRole';
}

{
  package UsesTheRole2;

  use Moo;

  with 'RollyRole';

  has '+f' => (default => sub { 2 });
}

{

  package ExtendsTheClass;

  use Moo;

  extends 'ClassyClass';

  has '+f' => (default => sub { 3 });
}

{
  package BlowsUp;

  use Moo;

  ::like(::exception { has '+f' => () }, qr/\Qhas '+f'/, 'Kaboom');
}

{
  package ClassyClass2;
  use Moo;
  has d => (is => 'ro', default => sub { 4 });
}

{
  package MultiClass;
  use Moo;
  extends 'ClassyClass', 'ClassyClass2';
  ::is(::exception {
    has '+f' => ();
  }, undef, 'extend attribute from first parent');
  ::like(::exception {
    has '+d' => ();
  }, qr/no d attribute already exists/,
    'can\'t extend attribute from second parent');
}

is(UsesTheRole->new->f, 0, 'role attr');
is(ClassyClass->new->f, 1, 'class attr');
is(UsesTheRole2->new->f, 2, 'role attr with +');
is(ExtendsTheClass->new->f, 3, 'class attr with +');

{
  package HasBuilderSub;
  use Moo;
  has f => (is => 'ro', builder => sub { __PACKAGE__ });
}

{
  package ExtendsBuilderSub;
  use Moo;
  extends 'HasBuilderSub';
  has '+f' => (init_arg => undef);
  sub _build_f { __PACKAGE__ }
}

is +ExtendsBuilderSub->new->_build_f, 'ExtendsBuilderSub',
  'build sub not replaced by +attr';
is +ExtendsBuilderSub->new->f, 'ExtendsBuilderSub',
  'correct build sub used after +attr';

{
  package HasDefault;
  use Moo;
  has guff => (is => 'ro', default => sub { 'guff' });
}

{
  package ExtendsWithBuilder;
  use Moo;
  extends 'HasDefault';
  has '+guff' => (builder => sub { 'welp' });
}

is +ExtendsWithBuilder->new->guff, 'welp',
  'builder can override default';

my @packages;
for my $cfg (['Lazy' => lazy => 1], ['']) {
  my ($name, %cfg) = @$cfg;
  eval qq{
    {
      package ${name}PlusRole;
      use Moo::Role;
      has '+attr' => (\%cfg, default => 1);
      push \@packages, __PACKAGE__;
    }
    {
      package ${name}AttrAndPlusRole;
      use Moo::Role;
      has attr => (is => 'ro', \%cfg, default => 2);
      has '+attr' => (default => 1);
      push \@packages, __PACKAGE__;
    }
    {
      package ${name}CompletePlusRole;
      use Moo::Role;
      has '+attr' => (is => 'ro', \%cfg, default => 1);
      push \@packages, __PACKAGE__;
    }
    {
      package ${name}PlusAndPlusRole;
      use Moo::Role;
      has '+attr' => (is => 'ro', \%cfg, default => 2);
      has '+attr' => (default => 1);
      push \@packages, __PACKAGE__;
    }
    {
      package ${name}AttrAfterPlusRole;
      use Moo::Role;
      has '+attr' => (default => 1);
      has attr => (is => 'ro', \%cfg, default => 2);
      push \@packages, __PACKAGE__;
    }
    1;
  } or die $@;
}

for my $role (@packages) {
  my $class = "ClassWith$role";
  eval qq{
    package $class;
    use Moo;
    has attr => (is => 'ro');
    with '$role';
    1;
  } or die $@;
  is $class->new->attr, 1, "correct value for $class";
}

done_testing;
