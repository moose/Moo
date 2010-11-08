package Method::Generate::BuildAll;

use strictures 1;
use base qw(Class::Tiny::Object);
use Sub::Quote;
use Class::Tiny::_mro;
use Class::Tiny::_Utils;

sub generate_method {
  my ($self, $into) = @_;
  my @builds =
    grep *{_getglob($_)}{CODE},
    map "${_}::BUILD",
    reverse @{mro::get_linear_isa($into)};
  quote_sub "${into}::BUILDALL", join '',
    qq{    my \$self = shift;\n},
    (map qq{    \$self->${_}(\@_);\n}, @builds),
    qq{    return \$self\n};
}

1;
