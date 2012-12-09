use strictures 1;
use Test::More;

# Compile-time exceptions, so need stringy eval; hence not Test::Fatal.
{
	local $@;
	ok not eval q { package XXX; use Moo; use Moo::Role; 1; };
	like $@, qr{Cannot import Moo::Role into a Moo class};
}

{
	local $@;
	ok not eval q { package YYY; use Moo::Role; use Moo; 1; };
	like $@, qr{Cannot import Moo into a role};
}

done_testing;
