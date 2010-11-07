package Method::Generate::Accessor;

use strictures 1;
use Class::Tiny::_Utils;
use base qw(Class::Tiny::Object);
use Sub::Quote;
use B 'perlstring';

sub generate_method {
  my ($self, $into, $name, $spec) = @_;
  die "Must have an is" unless my $is = $spec->{is};
  my $name_str = perlstring $name;
  my $body = do {
    if ($is eq 'ro') {
      $self->_generate_get($name_str)
    } elsif ($is eq 'rw') {
      $self->_generate_getset($name_str)
    } else {
      die "Unknown is ${is}";
    }
  };
  quote_sub "${into}::${name}" => '    '.$body."\n";
}

sub _generate_get {
  my ($self, $name_str) = @_;
  "\$_[0]->{${name_str}}";
}

sub _generate_set {
  my ($self, $name_str, $value) = @_;
  "\$_[0]->{${name_str}} = ${value}";
}

sub _generate_getset {
  my ($self, $name_str) = @_;
  q{(@_ > 1 ? }.$self->_generate_set($name_str, q{$_[1]})
    .' : '.$self->_generate_get($name_str).')';
}

1;
