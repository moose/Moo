package Method::Generate::BuildAll;

use strictures 1;
use base qw(Moo::Object);
use Sub::Quote;
use Moo::_mro;
use Moo::_Utils;

sub generate_method {
  my ($self, $into) = @_;
  quote_sub "${into}::BUILDALL", join '',
    qq{    my \$self = shift;\n},
    $self->buildall_body_for($into, '$self', '@_'),
    qq{    return \$self\n};
}

sub buildall_body_for {
  my ($self, $into, $me, $args) = @_;
  my @builds =
    grep *{_getglob($_)}{CODE},
    map "${_}::BUILD",
    reverse @{mro::get_linear_isa($into)};
  join '', map qq{    ${me}->${_}(${args});\n}, @builds;
}

1;
