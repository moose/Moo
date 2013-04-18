use strict;
use warnings;
use Test::More;

{
	package Dark::Side;
	use overload
		q[&{}]   => sub { shift->to_code },
		fallback => 1;
	sub new {
		my $class = shift;
		my $code = shift;
		bless \$code, $class;
	}
	sub to_code {
		my $self = shift;
		eval "sub { $$self }";
	}
}

{
	package The::Force;
	use Sub::Quote;
	use base 'Dark::Side';
	sub to_code {
		my $self = shift;
		return quote_sub $$self;
	}
}

my $darkside = Dark::Side->new('my $dummy = "join the dark side"; $_[0] * 2');
is($darkside->(6), 12, 'check Dark::Side coderef');

my $theforce = The::Force->new('my $dummy = "use the force Luke"; $_[0] * 2');
is($theforce->(6), 12, 'check The::Force coderef');

{
	package Doubleena;
	use Moo;
	has a => (is => "ro", coerce => $darkside, isa => sub { 1 });
	has b => (is => "ro", coerce => $theforce, isa => The::Force->new('my $z = "I am your father"'));
}

my $o = Doubleena->new(a => 11, b => 12);
is($o->a, 22, 'non-Sub::Quoted inlined coercion overload works');
is($o->b, 24, 'Sub::Quoted inlined coercion overload works');

use B::Deparse;
my $constructor = B::Deparse->new->coderef2text(Doubleena->can('new'));

like($constructor, qr{use the force Luke}, 'Sub::Quoted coercion got inlined');
unlike($constructor, qr{join the dark side}, 'non-Sub::Quoted coercion was not inlined');
like($constructor, qr{I am your father}, 'Sub::Quoted isa got inlined');

done_testing;
