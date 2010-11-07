package Method::Generate::Accessor;

use strictures 1;
use Class::Tiny::_Utils;
use base qw(Class::Tiny::Object);
use Sub::Quote;
use B 'perlstring';

sub generate_method {
  my ($self, $into, $name, $spec, $quote_opts) = @_;
  die "Must have an is" unless my $is = $spec->{is};
  local $self->{captures} = {};
  my $body = do {
    if ($is eq 'ro') {
      $self->_generate_get($name)
    } elsif ($is eq 'rw') {
      $self->_generate_getset($name, $spec)
    } else {
      die "Unknown is ${is}";
    }
  };
  quote_sub
    "${into}::${name}" => '    '.$body."\n",
    $self->{captures}, $quote_opts||{}
  ;
}

sub _generate_get {
  my ($self, $name) = @_;
  $self->_generate_simple_get('$_[0]', $name);
}

sub generate_simple_get {
  shift->_generate_simple_get(@_);
}

sub _generate_simple_get {
  my ($self, $me, $name) = @_;
  my $name_str = perlstring $name;
  "${me}->{${name_str}}";
}

sub _generate_set {
  my ($self, $name, $value, $spec) = @_;
  my $simple = $self->_generate_simple_set($name, $value);
  if (my $trigger = $spec->{trigger}) {
    my $value = '$value';
    my $fire = $self->_generate_trigger($name, '$_[0]', '$value', $trigger);
    return 'do { '
      .'my $value = '.$simple.'; '.$fire.'; '
      .'$value }'
    ;
  }
  return $simple;
}

sub generate_trigger {
  my $self = shift;
  local $self->{captures} = {};
  my $code = $self->_generate_trigger(@_);
  return ($code, $self->{captures});
}

sub _generate_trigger {
  my ($self, $name, $obj, $value, $trigger) = @_;
  if (my $quoted = quoted_from_sub($trigger)) {
    my $code = $quoted->[1];
    my $at_ = 'local @_ = ('.join(', ', $obj, $value).');';
    if (my $captures = $quoted->[2]) {
      my $cap_name = qq{\$trigger_captures_for_${name}};
      $self->{captures}->{$cap_name} = \$captures;
      return "do {\n".'      '.$at_."\n"
        .Sub::Quote::capture_unroll($cap_name, $captures, 6)
        ."     ${code}\n    }";
    }
    return 'do { local @_ = ('.join(', ', $obj, $value).'); '.$code.' }';
  }
  my $cap_name = qq{\$trigger_for_${name}};
  $self->{captures}->{$cap_name} = \$trigger;
  return "${cap_name}->(${obj}, ${value})";
}

sub _generate_simple_set {
  my ($self, $name, $value) = @_;
  my $name_str = perlstring $name;
  "\$_[0]->{${name_str}} = ${value}";
}

sub _generate_getset {
  my ($self, $name, $spec) = @_;
  q{(@_ > 1 ? }.$self->_generate_set($name, q{$_[1]}, $spec)
    .' : '.$self->_generate_get($name).')';
}

1;
