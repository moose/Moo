package Method::Generate::Accessor;

use strictures 1;
use Moo::_Utils;
use base qw(Moo::Object);
use Sub::Quote;
use B 'perlstring';
BEGIN {
  our $CAN_HAZ_XS =
    _maybe_load_module('Class::XSAccessor')
      &&
    (Class::XSAccessor->VERSION > 1.06)
  ;
}

sub generate_method {
  my ($self, $into, $name, $spec, $quote_opts) = @_;
  die "Must have an is" unless my $is = $spec->{is};
  local $self->{captures} = {};
  my $body = do {
    if ($is eq 'ro') {
      if (our $CAN_HAZ_XS && $self->is_simple_get($name, $spec)) {
        $self->_generate_xs_get($into, $name);
      } else {
        $self->_generate_get($name, $spec)
      }
    } elsif ($is eq 'rw') {
      if (
        our $CAN_HAZ_XS
        && $self->is_simple_get($name, $spec)
        && $self->is_simple_set($name, $spec)
      ) {
        $self->_generate_xs_getset($into, $name);
      } else {
        $self->_generate_getset($name, $spec)
      }
    } else {
      die "Unknown is ${is}";
    }
  };
  if (my $pred = $spec->{predicate}) {
    quote_sub "${into}::${pred}" =>
    '    '.$self->_generate_simple_has('$_[0]', $name)."\n"
    ;
  }
  if (my $cl = $spec->{clearer}) {
    quote_sub "${into}::${cl}" => 
      "    delete \$_[0]->{${\perlstring $name}}\n"
    ;
  }
  if (ref($body)) {
    $body;
  } else {
    quote_sub
      "${into}::${name}" => '    '.$body."\n",
      $self->{captures}, $quote_opts||{}
    ;
  }
}

sub is_simple_attribute {
  my ($self, $name, $spec) = @_;
  # clearer doesn't have to be listed because it doesn't
  # affect whether defined/exists makes a difference
  !grep $spec->{$_},
    qw(lazy default builder isa trigger predicate);
}

sub is_simple_get {
  my ($self, $name, $spec) = @_;
  !($spec->{lazy} and ($spec->{default} or $spec->{builder}));
}

sub is_simple_set {
  my ($self, $name, $spec) = @_;
  !grep $spec->{$_}, qw(isa trigger);
}

sub _generate_get {
  my ($self, $name, $spec) = @_;
  my $simple = $self->_generate_simple_get('$_[0]', $name);
  if ($self->is_simple_get($name, $spec)) {
    $simple;
  } else {
    'do { '.$self->_generate_use_default(
      '$_[0]', $name, $spec,
      $self->_generate_simple_has('$_[0]', $name),
    ).'; '.$simple.' }';
  }
}

sub _generate_simple_has {
  my ($self, $me, $name) = @_;
  "exists ${me}->{${\perlstring $name}}";
}

sub generate_get_default {
  my $self = shift;
  local $self->{captures} = {};
  my $code = $self->_generate_get_default(@_);
  ($code, $self->{captures});
}

sub _generate_use_default {
  my ($self, $me, $name, $spec, $test) = @_;
  $self->_generate_simple_set(
    $me, $name, $self->_generate_get_default($me, $name, $spec)
  ).' unless '.$test;
}

sub _generate_get_default {
  my ($self, $me, $name, $spec) = @_;
  $spec->{default}
    ? $self->_generate_call_code($name, 'default', $me, $spec->{default})
    : "${me}->${\$spec->{builder}}"
}

sub generate_simple_get {
  my ($self, @args) = @_;
  $self->_generate_simple_get(@args);
}

sub _generate_simple_get {
  my ($self, $me, $name) = @_;
  my $name_str = perlstring $name;
  "${me}->{${name_str}}";
}

sub _generate_set {
  my ($self, $name, $value, $spec) = @_;
  my $simple = $self->_generate_simple_set('$_[0]', $name, $value);
  if ($self->is_simple_set($name, $spec)) {
    $simple;
  } else {
    my ($trigger, $isa_check) = @{$spec}{qw(trigger isa)};
    my $code = "do {\n";
    if ($isa_check) {
      $code .= 
        "        ".$self->_generate_isa_check($name, '$_[1]', $isa_check).";\n";
    }
    if ($trigger) {
      my $fire = $self->_generate_trigger($name, '$_[0]', '$value', $trigger);
      $code .=
        "        my \$value = ".$simple.";\n        ".$fire.";\n"
        ."        \$value;\n";
    } else {
      $code .= "        ".$simple.";\n";
    }
    $code .= "      }";
    $code;
  }
}
  
sub generate_trigger {
  my $self = shift;
  local $self->{captures} = {};
  my $code = $self->_generate_trigger(@_);
  ($code, $self->{captures});
}

sub _generate_trigger {
  my ($self, $name, $obj, $value, $trigger) = @_;
  $self->_generate_call_code($name, 'trigger', "${obj}, ${value}", $trigger);
}

sub generate_isa_check {
  my ($self, @args) = @_;
  local $self->{captures} = {};
  my $code = $self->_generate_isa_check(@args);
  ($code, $self->{captures});
}

sub _generate_isa_check {
  my ($self, $name, $value, $check) = @_;
  $self->_generate_call_code($name, 'isa_check', $value, $check);
}

sub _generate_call_code {
  my ($self, $name, $type, $values, $sub) = @_;
  if (my $quoted = quoted_from_sub($sub)) {
    my $code = $quoted->[1];
    my $at_ = 'local @_ = ('.$values.');';
    if (my $captures = $quoted->[2]) {
      my $cap_name = qq{\$${type}_captures_for_${name}};
      $self->{captures}->{$cap_name} = \$captures;
      return "do {\n".'      '.$at_."\n"
        .Sub::Quote::capture_unroll($cap_name, $captures, 6)
        ."     ${code}\n    }";
    }
    'do { local @_ = ('.$values.'); '.$code.' }';
  } else {
    my $cap_name = qq{\$${type}_for_${name}};
    $self->{captures}->{$cap_name} = \$sub;
    "${cap_name}->(${values})";
  }
}

sub generate_populate_set {
  my $self = shift;
  local $self->{captures} = {};
  my $code = $self->_generate_populate_set(@_);
  ($code, $self->{captures});
}

sub _generate_populate_set {
  my ($self, $me, $name, $spec, $source, $test) = @_;
  if (!$spec->{lazy} and
        ($spec->{default} or $spec->{builder})) {
    my $get_indent = ' ' x ($spec->{isa} ? 6 : 4);
    my $get_value = 
      "(\n${get_indent}  ${test}\n${get_indent}   ? ${source}\n${get_indent}   : "
        .$self->_generate_get_default(
          '$new', $_, $spec
        )
        ."\n${get_indent})";
    ($spec->{isa}
      ? "    {\n      my \$value = ".$get_value.";\n      "
        .$self->_generate_isa_check(
          $name, '$value', $spec->{isa}
        ).";\n"
        .'      '.$self->_generate_simple_set($me, $name, '$value').";\n"
        ."    }\n"
      : '    '.$self->_generate_simple_set($me, $name, $get_value).";\n"
    )
    .($spec->{trigger}
      ? '    '
        .$self->_generate_trigger(
          $name, $me, $self->_generate_simple_get($me, $name),
          $spec->{trigger}
        )." if ${test};\n"
      : ''
    );
  } else {
    "    if (${test}) {\n"
      .($spec->{isa}
        ? "      "
          .$self->_generate_isa_check(
            $name, $source, $spec->{isa}
          ).";\n"
        : ""
      )
      ."      ".$self->_generate_simple_set($me, $name, $source).";\n"
      .($spec->{trigger}
        ? "      "
          .$self->_generate_trigger(
            $name, $me, $self->_generate_simple_get($me, $name),
            $spec->{trigger}
          ).";\n"
        : ""
      )
      ."    }\n";
  }
}

sub generate_multi_set {
  my ($self, $me, $to_set, $from) = @_;
  "\@{${me}}{qw(${\join ' ', @$to_set})} = $from";
}

sub generate_simple_set {
  my $self = shift;
  local $self->{captures} = {};
  my $code = $self->_generate_simple_set(@_);
  ($code, $self->{captures});
}

sub _generate_simple_set {
  my ($self, $me, $name, $value) = @_;
  my $name_str = perlstring $name;
  "${me}->{${name_str}} = ${value}";
}

sub _generate_getset {
  my ($self, $name, $spec) = @_;
  q{(@_ > 1}."\n      ? ".$self->_generate_set($name, q{$_[1]}, $spec)
    ."\n      : ".$self->_generate_get($name)."\n    )";
}

sub _generate_xs_get {
  shift->_generate_xs('getters', @_);
}

sub _generate_xs_getset {
  shift->_generate_xs('accessors', @_);
}

sub _generate_xs {
  my ($self, $type, $into, $name) = @_;
  no strict 'refs';
  Class::XSAccessor->import(
    class => $into,
    $type => { $name => $name }
  );
  $into->can($name);
}

1;
