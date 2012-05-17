package Moo;

use strictures 1;
use Moo::_Utils;
use B 'perlstring';
use Sub::Defer ();

our $VERSION = '0.091007'; # 0.91.7
$VERSION = eval $VERSION;

require Moo::sification;

our %MAKERS;

sub import {
  my $target = caller;
  my $class = shift;
  strictures->import;
  return if $MAKERS{$target}; # already exported into this package
  _install_coderef "${target}::extends" => "Moo::extends" => sub {
    _load_module($_) for @_;
    # Can't do *{...} = \@_ or 5.10.0's mro.pm stops seeing @ISA
    @{*{_getglob("${target}::ISA")}{ARRAY}} = @_;
    if (my $old = delete $Moo::MAKERS{$target}{constructor}) {
      delete _getstash($target)->{new};
      Moo->_constructor_maker_for($target)
         ->register_attribute_specs(%{$old->all_attribute_specs});
    }
    $Moo::HandleMoose::MOUSE{$target} = [
      grep defined, map Mouse::Util::find_meta($_), @_
    ] if $INC{"Mouse.pm"};
    $class->_maybe_reset_handlemoose($target);
    return;
  };
  _install_coderef "${target}::with" => "Moo::with" => sub {
    require Moo::Role;
    Moo::Role->apply_roles_to_package($target, $_[0]);
    $class->_maybe_reset_handlemoose($target);
  };
  $MAKERS{$target} = {};
  _install_coderef "${target}::has" => "Moo::has" => sub {
    my ($name, %spec) = @_;
    $class->_constructor_maker_for($target)
          ->register_attribute_specs($name, \%spec);
    $class->_accessor_maker_for($target)
          ->generate_method($target, $name, \%spec);
    $class->_maybe_reset_handlemoose($target);
    return;
  };
  foreach my $type (qw(before after around)) {
    _install_coderef "${target}::${type}" => "Moo::${type}" => sub {
      require Class::Method::Modifiers;
      _install_modifier($target, $type, @_);
      return;
    };
  }
  {
    no strict 'refs';
    @{"${target}::ISA"} = do {
      require Moo::Object; ('Moo::Object');
    } unless @{"${target}::ISA"};
  }
  if ($INC{'Moo/HandleMoose.pm'}) {
    Moo::HandleMoose::inject_fake_metaclass_for($target);
  }
}

sub _maybe_reset_handlemoose {
  my ($class, $target) = @_;
  if ($INC{"Moo/HandleMoose.pm"}) {
    Moo::HandleMoose::maybe_reinject_fake_metaclass_for($target);
  }
}

sub _accessor_maker_for {
  my ($class, $target) = @_;
  return unless $MAKERS{$target};
  $MAKERS{$target}{accessor} ||= do {
    my $maker_class = do {
      if (my $m = do {
            if (my $defer_target = 
                  (Sub::Defer::defer_info($target->can('new'))||[])->[0]
              ) {
              my ($pkg) = ($defer_target =~ /^(.*)::[^:]+$/);
              $MAKERS{$pkg} && $MAKERS{$pkg}{accessor};
            } else {
              undef;
            }
          }) {
        ref($m);
      } else {
        require Method::Generate::Accessor;
        'Method::Generate::Accessor'
      }
    };
    $maker_class->new;
  }
}

sub _constructor_maker_for {
  my ($class, $target, $select_super) = @_;
  return unless $MAKERS{$target};
  $MAKERS{$target}{constructor} ||= do {
    require Method::Generate::Constructor;
    require Sub::Defer;
    my ($moo_constructor, $con);

    if ($select_super && $MAKERS{$select_super}) {
      $moo_constructor = 1;
      $con = $MAKERS{$select_super}{constructor};
    } else {
      my $t_new = $target->can('new');
      if ($t_new) {
        if ($t_new == Moo::Object->can('new')) {
          $moo_constructor = 1;
        } elsif (my $defer_target = (Sub::Defer::defer_info($t_new)||[])->[0]) {
          my ($pkg) = ($defer_target =~ /^(.*)::[^:]+$/);
          if ($MAKERS{$pkg}) {
            $moo_constructor = 1;
            $con = $MAKERS{$pkg}{constructor};
          }
        }
      } else {
        $moo_constructor = 1; # no other constructor, make a Moo one
      }
    };
    ($con ? ref($con) : 'Method::Generate::Constructor')
      ->new(
        package => $target,
        accessor_generator => $class->_accessor_maker_for($target),
        construction_string => (
          $moo_constructor
            ? ($con ? $con->construction_string : undef)
            : ('$class->'.$target.'::SUPER::new(@_)')
        ),
        subconstructor_handler => (
          '      if ($Moo::MAKERS{$class}) {'."\n"
          .'        '.$class.'->_constructor_maker_for($class,'.perlstring($target).');'."\n"
          .'        return $class->new(@_)'.";\n"
          .'      }'."\n"
        ),
      )
      ->install_delayed
      ->register_attribute_specs(%{$con?$con->all_attribute_specs:{}})
  }
}

1;
=pod

=encoding utf-8

=head1 NAME

Moo - Minimalist Object Orientation (with Moose compatiblity)

=head1 SYNOPSIS

 package Cat::Food;

 use Moo;
 use Sub::Quote;

 sub feed_lion {
   my $self = shift;
   my $amount = shift || 1;

   $self->pounds( $self->pounds - $amount );
 }

 has taste => (
   is => 'ro',
 );

 has brand => (
   is  => 'ro',
   isa => sub {
     die "Only SWEET-TREATZ supported!" unless $_[0] eq 'SWEET-TREATZ'
   },
);

 has pounds => (
   is  => 'rw',
   isa => quote_sub q{ die "$_[0] is too much cat food!" unless $_[0] < 15 },
 );

 1;

and else where

 my $full = Cat::Food->new(
    taste  => 'DELICIOUS.',
    brand  => 'SWEET-TREATZ',
    pounds => 10,
 );

 $full->feed_lion;

 say $full->pounds;

=head1 DESCRIPTION

This module is an extremely light-weight, high-performance L<Moose> replacement.
It also avoids depending on any XS modules to allow simple deployments.  The
name C<Moo> is based on the idea that it provides almost -but not quite- two
thirds of L<Moose>.

Unlike C<Mouse> this module does not aim at full L<Moose> compatibility.  See
L</INCOMPATIBILITIES> for more details.

=head1 WHY MOO EXISTS

If you want a full object system with a rich Metaprotocol, L<Moose> is
already wonderful.

I've tried several times to use L<Mouse> but it's 3x the size of Moo and
takes longer to load than most of my Moo based CGI scripts take to run.

If you don't want L<Moose>, you don't want "less metaprotocol" like L<Mouse>,
you want "as little as possible" - which means "no metaprotocol", which is
what Moo provides.

By Moo 1.0 I intend to have Moo's equivalent of L<Any::Moose> built in -
if Moose gets loaded, any Moo class or role will act as a Moose equivalent
if treated as such.

Hence - Moo exists as its name - Minimal Object Orientation - with a pledge
to make it smooth to upgrade to L<Moose> when you need more than minimal
features.

=head1 Moo and Moose - NEW, EXPERIMENTAL

If L<Moo> detects L<Moose> being loaded, it will automatically register
metaclasses for your L<Moo> and L<Moo::Role> packages, so you should be able
to use them in L<Moose> code without it ever realising you aren't using
L<Moose> everywhere.

Extending a L<Moose> class or consuming a L<Moose::Role> should also work.

So should extending a L<Mouse> class or consuming a L<Mouse::Role>.

This means that there is no need for anything like L<Any::Moose> for Moo
code - Moo and Moose code should simply interoperate without problem. To
handle L<Mouse> code, you'll likely need an empty Moo role or class consuming
or extending the L<Mouse> stuff since it doesn't register true L<Moose>
metaclasses like we do.

However, these features are new as of 0.91.0 (0.091000) so while serviceable,
they are absolutely certain to not be 100% yet; please do report bugs.

If you need to disable the metaclass creation, add:

  no Moo::sification;

to your code before Moose is loaded, but bear in mind that this switch is
currently global and turns the mechanism off entirely, so don't put this
in library code, only in a top level script as a temporary measure while
you send a bug report.

=head1 IMPORTED METHODS

=head2 new

 Foo::Bar->new( attr1 => 3 );

or

 Foo::Bar->new({ attr1 => 3 });

=head2 BUILDARGS

 sub BUILDARGS {
   my ( $class, @args ) = @_;

   unshift @args, "attr1" if @args % 2 == 1;

   return { @args };
 };

 Foo::Bar->new( 3 );

The default implementation of this method accepts a hash or hash reference of
named parameters. If it receives a single argument that isn't a hash reference
it throws an error.

You can override this method in your class to handle other types of options
passed to the constructor.

This method should always return a hash reference of named options.

=head2 BUILD

Define a C<BUILD> method on your class and the constructor will automatically
call the C<BUILD> method from parent down to child after the object has
been instantiated.  Typically this is used for object validation or possibly
logging.

=head2 DEMOLISH

If you have a C<DEMOLISH> method anywhere in your inheritance hierarchy,
a C<DESTROY> method is created on first object construction which will call
C<< $instance->DEMOLISH($in_global_destruction) >> for each C<DEMOLISH>
method from child upwards to parents.

Note that the C<DESTROY> method is created on first construction of an object
of your class in order to not add overhead to classes without C<DEMOLISH>
methods; this may prove slightly surprising if you try and define your own.

=head2 does

 if ($foo->does('Some::Role1')) {
   ...
 }

Returns true if the object composes in the passed role.

=head1 IMPORTED SUBROUTINES

=head2 extends

 extends 'Parent::Class';

Declares base class. Multiple superclasses can be passed for multiple
inheritance (but please use roles instead).

Calling extends more than once will REPLACE your superclasses, not add to
them like 'use base' would.

=head2 with

 with 'Some::Role1';

or

 with 'Some::Role1', 'Some::Role2';

Composes one or more L<Moo::Role> (or L<Role::Tiny>) roles into the current
class.  An error will be raised if these roles have conflicting methods.

=head2 has

 has attr => (
   is => 'ro',
 );

Declares an attribute for the class.

The options for C<has> are as follows:

=over 2

=item * is

B<required>, may be C<ro>, C<lazy>, C<rwp> or C<rw>.

C<ro> generates an accessor that dies if you attempt to write to it - i.e.
a getter only - by defaulting C<reader> to the name of the attribute.

C<lazy> generates a reader like C<ro>, but also sets C<lazy> to 1 and
C<builder> to C<_build_${attribute_name}> to allow on-demand generated
attributes.  This feature was my attempt to fix my incompetence when
originally designing C<lazy_build>, and is also implemented by
L<MooseX::AttributeShortcuts>.

C<rwp> generates a reader like C<ro>, but also sets C<writer> to
C<_set_${attribute_name}> for attributes that are designed to be written
from inside of the class, but read-only from outside.
This feature comes from L<MooseX::AttributeShortcuts>.

C<rw> generates a normal getter/setter by defaulting C<accessor> to the
name of the attribute.

=item * isa

Takes a coderef which is meant to validate the attribute.  Unlike L<Moose> Moo
does not include a basic type system, so instead of doing C<< isa => 'Num' >>,
one should do

 isa => quote_sub q{
   die "$_[0] is not a number!" unless looks_like_number $_[0]
 },

L<Sub::Quote aware|/SUB QUOTE AWARE>

Since L<Moo> does B<not> run the C<isa> check before C<coerce> if a coercion
subroutine has been supplied, C<isa> checks are not structural to your code
and can, if desired, be omitted on non-debug builds (although if this results
in an uncaught bug causing your program to break, the L<Moo> authors guarantee
nothing except that you get to keep both halves).

If you want L<MooseX::Types> style named types, look at
L<MooX::Types::MooseLike>.

To cause your C<isa> entries to be automatically mapped to named
L<Moose::Meta::TypeConstraint> objects (rather than the default behaviour
of creating an anonymous type), set:

  $Moo::HandleMoose::TYPE_MAP{$isa_coderef} = sub {
    require MooseX::Types::Something;
    return MooseX::Types::Something::TypeName();
  };

Note that this example is purely illustrative; anything that returns a
L<Moose::Meta::TypeConstraint> object or something similar enough to it to
make L<Moose> happy is fine.

=item * coerce

Takes a coderef which is meant to coerce the attribute.  The basic idea is to
do something like the following:

 coerce => quote_sub q{
   $_[0] + 1 unless $_[0] % 2
 },

Note that L<Moo> will always fire your coercion - this is to permit
isa entries to be used purely for bug trapping, whereas coercions are
always structural to your code. We do, however, apply any supplied C<isa>
check after the coercion has run to ensure that it returned a valid value.

L<Sub::Quote aware|/SUB QUOTE AWARE>

=item * handles

Takes a string

  handles => 'RobotRole'

Where C<RobotRole> is a role (L<Moo::Role>) that defines an interface which
becomes the list of methods to handle.

Takes a list of methods

 handles => [ qw( one two ) ]

Takes a hashref

 handles => {
   un => 'one',
 }

=item * trigger

Takes a coderef which will get called any time the attribute is set. This
includes the constructor. Coderef will be invoked against the object with the
new value as an argument.

If you set this to just C<1>, it generates a trigger which calls the
C<_trigger_${attr_name}> method on C<$self>. This feature comes from
L<MooseX::AttributeShortcuts>.

Note that Moose also passes the old value, if any; this feature is not yet
supported.

L<Sub::Quote aware|/SUB QUOTE AWARE>

=item * default

Takes a coderef which will get called with $self as its only argument
to populate an attribute if no value is supplied to the constructor - or
if the attribute is lazy, when the attribute is first retrieved if no
value has yet been provided.

Note that if your default is fired during new() there is no guarantee that
other attributes have been populated yet so you should not rely on their
existence.

L<Sub::Quote aware|/SUB QUOTE AWARE>

=item * predicate

Takes a method name which will return true if an attribute has a value.

If you set this to just C<1>, the predicate is automatically named
C<has_${attr_name}> if your attribute's name does not start with an
underscore, or <_has_${attr_name_without_the_underscore}> if it does.
This feature comes from L<MooseX::AttributeShortcuts>.

=item * builder

Takes a method name which will be called to create the attribute - functions
exactly like default except that instead of calling

  $default->($self);

Moo will call

  $self->$builder;

If you set this to just C<1>, the predicate is automatically named
C<_build_${attr_name}>.  This feature comes from L<MooseX::AttributeShortcuts>.

=item * clearer

Takes a method name which will clear the attribute.

If you set this to just C<1>, the clearer is automatically named
C<clear_${attr_name}> if your attribute's name does not start with an
underscore, or <_clear_${attr_name_without_the_underscore}> if it does.
This feature comes from L<MooseX::AttributeShortcuts>.

=item * lazy

B<Boolean>.  Set this if you want values for the attribute to be grabbed
lazily.  This is usually a good idea if you have a L</builder> which requires
another attribute to be set.

=item * required

B<Boolean>.  Set this if the attribute must be passed on instantiation.

=item * reader

The value of this attribute will be the name of the method to get the value of
the attribute.  If you like Java style methods, you might set this to
C<get_foo>

=item * writer

The value of this attribute will be the name of the method to set the value of
the attribute.  If you like Java style methods, you might set this to
C<set_foo>

=item * weak_ref

B<Boolean>.  Set this if you want the reference that the attribute contains to
be weakened; use this when circular references are possible, which will cause
leaks.

=item * init_arg

Takes the name of the key to look for at instantiation time of the object.  A
common use of this is to make an underscored attribute have a non-underscored
initialization name. C<undef> means that passing the value in on instantiation
is ignored.

=back

=head2 before

 before foo => sub { ... };

See L<< Class::Method::Modifiers/before method(s) => sub { ... } >> for full
documentation.

=head2 around

 around foo => sub { ... };

See L<< Class::Method::Modifiers/around method(s) => sub { ... } >> for full
documentation.

=head2 after

 after foo => sub { ... };

See L<< Class::Method::Modifiers/after method(s) => sub { ... } >> for full
documentation.

=head1 SUB QUOTE AWARE

L<Sub::Quote/quote_sub> allows us to create coderefs that are "inlineable,"
giving us a handy, XS-free speed boost.  Any option that is L<Sub::Quote>
aware can take advantage of this.

=head1 INCOMPATIBILITIES WITH MOOSE

There is no built in type system.  C<isa> is verified with a coderef, if you
need complex types, just make a library of coderefs, or better yet, functions
that return quoted subs. L<MooX::Types::MooseLike> provides a similar API
to L<MooseX::Types::Moose> so that you can write

  has days_to_live => (is => 'ro', isa => Int);

and have it work with both; it is hoped that providing only subrefs as an
API will encourage the use of other type systems as well, since it's
probably the weakest part of Moose design-wise.

C<initializer> is not supported in core since the author considers it to be a
bad idea but may be supported by an extension in future. Meanwhile C<trigger> or
C<coerce> are more likely to be able to fulfill your needs.

There is no meta object.  If you need this level of complexity you wanted
L<Moose> - Moo succeeds at being small because it explicitly does not
provide a metaprotocol. However, if you load L<Moose>, then

  Class::MOP::class_of($moo_class_or_role)

will return an appropriate metaclass pre-populated by L<Moo>.

No support for C<super>, C<override>, C<inner>, or C<augment> - override can
be handled by around albeit with a little more typing, and the author considers
augment to be a bad idea.

The C<dump> method is not provided by default. The author suggests loading
L<Devel::Dwarn> into C<main::> (via C<perl -MDevel::Dwarn ...> for example) and
using C<$obj-E<gt>$::Dwarn()> instead.

L</default> only supports coderefs, because doing otherwise is usually a
mistake anyway.

C<lazy_build> is not supported; you are instead encouraged to use the
C<is => 'lazy'> option supported by L<Moo> and L<MooseX::AttributeShortcuts>.

C<auto_deref> is not supported since the author considers it a bad idea.

C<documentation> will show up in a L<Moose> metaclass created from your class
but is otherwise ignored. Then again, L<Moose> ignores it as well, so this
is arguably not an incompatibility.

Since C<coerce> does not require C<isa> to be defined but L<Moose> does
require it, the metaclass inflation for coerce-alone is a trifle insane
and if you attempt to subtype the result will almost certainly break.

Handling of warnings: when you C<use Moo> we enable FATAL warnings.  The nearest
similar invocation for L<Moose> would be:

  use Moose;
  use warnings FATAL => "all";

Additionally, L<Moo> supports a set of attribute option shortcuts intended to
reduce common boilerplate.  The set of shortcuts is the same as in the L<Moose>
module L<MooseX::AttributeShortcuts> as of its version 0.009+.  So if you:

    package MyClass;
    use Moo;

The nearest L<Moose> invocation would be:

    package MyClass;

    use Moose;
    use warnings FATAL => "all";
    use MooseX::AttributeShortcuts;

or, if you're inheriting from a non-Moose class,

    package MyClass;

    use Moose;
    use MooseX::NonMoose;
    use warnings FATAL => "all";
    use MooseX::AttributeShortcuts;

Finally, Moose requires you to call

    __PACKAGE__->meta->make_immutable;

at the end of your class to get an inlined (i.e. not horribly slow)
constructor. Moo does it automatically the first time ->new is called
on your class.

=head1 SUPPORT

IRC: #web-simple on irc.perl.org

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

dg - David Leadbeater (cpan:DGL) <dgl@dgl.cx>

frew - Arthur Axel "fREW" Schmidt (cpan:FREW) <frioux@gmail.com>

hobbs - Andrew Rodland (cpan:ARODLAND) <arodland@cpan.org>

jnap - John Napiorkowski (cpan:JJNAPIORK) <jjn1056@yahoo.com>

ribasushi - Peter Rabbitson (cpan:RIBASUSHI) <ribasushi@cpan.org>

chip - Chip Salzenberg (cpan:CHIPS) <chip@pobox.com>

ajgb - Alex J. G. Burzyński (cpan:AJGB) <ajgb@cpan.org>

doy - Jesse Luehrs (cpan:DOY) <doy at tozt dot net>

perigrin - Chris Prather (cpan:PERIGRIN) <chris@prather.org>

=head1 COPYRIGHT

Copyright (c) 2010-2011 the Moo L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
