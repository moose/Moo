use strictures 1;
use Test::More;

# Compile-time exceptions, so need stringy eval; hence not Test::Fatal.
{
  local $@;
  ok !eval q { package ZZZ; use Role::Tiny; use Moo; 1; },
    "can't import Moo into a Role::Tiny role";
  like $@, qr{Cannot import Moo into a role},
    " ... with correct error message";
}

{
  local $@;
  ok !eval q { package XXX; use Moo; use Moo::Role; 1; },
    "can't import Moo::Role into a Moo class";
  like $@, qr{Cannot import Moo::Role into a Moo class},
    " ... with correct error message";
}

{
  local $@;
  ok !eval q { package YYY; use Moo::Role; use Moo; 1; },
    "can't import Moo into a Moo role";
  like $@, qr{Cannot import Moo into a role},
    " ... with correct error message";
}

done_testing;
