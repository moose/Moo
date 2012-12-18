package Method::Generate::Accessor;

use strictures 1;
use Moo::_Utils;
use base qw(Moo::Object);
use Sub::Quote;
use B 'perlstring';
use Scalar::Util 'blessed';
use overload ();
BEGIN {
  our $CAN_HAZ_XS =
    !$ENV{MOO_XS_DISABLE}
      &&
    _maybe_load_module('Class::XSAccessor')
      &&
    (eval { Class::XSAccessor->VERSION('1.07') })
  ;
}

sub generate_method {
  my ($self, $into, $name, $spec, $quote_opts) = @_;
  $name =~ s/^\+//;
  die "Must have an is" unless my $is = $spec->{is};
  if ($is eq 'ro') {
    $spec->{reader} = $name unless exists $spec->{reader};
  } elsif ($is eq 'rw') {
    $spec->{accessor} = $name unless exists $spec->{accessor}
      or ( $spec->{reader} and $spec->{writer} );
  } elsif ($is eq 'lazy') {
    $spec->{reader} = $name unless exists $spec->{reader};
    $spec->{lazy} = 1;
    $spec->{builder} ||= '_build_'.$name unless $spec->{default};
  } elsif ($is eq 'rwp') {
    $spec->{reader} = $name unless exists $spec->{reader};
    $spec->{writer} = "_set_${name}" unless exists $spec->{writer};
  } elsif ($is ne 'bare') {
    die "Unknown is ${is}";
  }
  if (exists $spec->{builder}) {
    if(ref $spec->{builder}) {
      die "Invalid builder for $into->$name - not a method name, coderef or"
        . " code-convertible object"
        unless ref $spec->{builder} eq 'CODE'
        or (blessed($spec->{builder}) and eval { \&{$spec->{builder}} });
      $spec->{builder_sub} = $spec->{builder};
      $spec->{builder} = 1;
    }
    $spec->{builder} = '_build_'.$name if ($spec->{builder}||0) eq 1;
    die "Invalid builder for $into->$name - not a valid method name"
      if $spec->{builder} !~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;
  }
  if (($spec->{predicate}||0) eq 1) {
    $spec->{predicate} = $name =~ /^_/ ? "_has${name}" : "has_${name}";
  }
  if (($spec->{clearer}||0) eq 1) {
    $spec->{clearer} = $name =~ /^_/ ? "_clear${name}" : "clear_${name}";
  }
  if (($spec->{trigger}||0) eq 1) {
    $spec->{trigger} = quote_sub('shift->_trigger_'.$name.'(@_)');
  }

  for my $setting (qw( default coerce )) {
    next if !exists $spec->{$setting};
    my $value = $spec->{$setting};
    my $invalid = "Invalid $setting '" . overload::StrVal($value)
      . "' for $into->$name - not a coderef";
    die "$invalid or code-convertible object"
      unless ref $value and (ref $value eq 'CODE' or blessed($value));
    die "$invalid and could not be converted to a coderef: $@"
      if !eval { \&$value };
  }

  my %methods;
  if (my $reader = $spec->{reader}) {
    if (our $CAN_HAZ_XS && $self->is_simple_get($name, $spec)) {
      $methods{$reader} = $self->_generate_xs(
        getters => $into, $reader, $name, $spec
      );
    } else {
      $self->{captures} = {};
      $methods{$reader} =
        quote_sub "${into}::${reader}"
          => '    die "'.$reader.' is a read-only accessor" if @_ > 1;'."\n"
             .$self->_generate_get($name, $spec)
          => delete $self->{captures}
        ;
    }
  }
  if (my $accessor = $spec->{accessor}) {
    if (
      our $CAN_HAZ_XS
      && $self->is_simple_get($name, $spec)
      && $self->is_simple_set($name, $spec)
    ) {
      $methods{$accessor} = $self->_generate_xs(
        accessors => $into, $accessor, $name, $spec
      );
    } else {
      $self->{captures} = {};
      $methods{$accessor} =
        quote_sub "${into}::${accessor}"
          => $self->_generate_getset($name, $spec)
          => delete $self->{captures}
        ;
    }
  }
  if (my $writer = $spec->{writer}) {
    if (
      our $CAN_HAZ_XS
      && $self->is_simple_set($name, $spec)
    ) {
      $methods{$writer} = $self->_generate_xs(
        setters => $into, $writer, $name, $spec
      );
    } else {
      $self->{captures} = {};
      $methods{$writer} =
        quote_sub "${into}::${writer}"
          => $self->_generate_set($name, $spec)
          => delete $self->{captures}
        ;
    }
  }
  if (my $pred = $spec->{predicate}) {
    $methods{$pred} =
      quote_sub "${into}::${pred}" =>
        '    '.$self->_generate_simple_has('$_[0]', $name, $spec)."\n"
      ;
  }
  if (my $pred = $spec->{builder_sub}) {
    _install_coderef( "${into}::$spec->{builder}" => $spec->{builder_sub} );
  }
  if (my $cl = $spec->{clearer}) {
    $methods{$cl} =
      quote_sub "${into}::${cl}" => 
        $self->_generate_simple_clear('$_[0]', $name, $spec)."\n"
      ;
  }
  if (my $hspec = $spec->{handles}) {
    my $asserter = $spec->{asserter} ||= '_assert_'.$name;
    my @specs = do {
      if (ref($hspec) eq 'ARRAY') {
        map [ $_ => $_ ], @$hspec;
      } elsif (ref($hspec) eq 'HASH') {
        map [ $_ => ref($hspec->{$_}) ? @{$hspec->{$_}} : $hspec->{$_} ],
          keys %$hspec;
      } elsif (!ref($hspec)) {
        map [ $_ => $_ ], Role::Tiny->methods_provided_by($hspec);
      } else {
        die "You gave me a handles of ${hspec} and I have no idea why";
      }
    };
    foreach my $spec (@specs) {
      my ($proxy, $target, @args) = @$spec;
      $self->{captures} = {};
      $methods{$proxy} =
        quote_sub "${into}::${proxy}" =>
          $self->_generate_delegation($asserter, $target, \@args),
          delete $self->{captures}
        ;
    }
  }
  if (my $asserter = $spec->{asserter}) {
    $self->{captures} = {};
    $methods{$asserter} =
      quote_sub "${into}::${asserter}" =>
        'do { '.$self->_generate_get($name, $spec).qq! }||die "Attempted to access '${name}' but it is not set"!,
        delete $self->{captures}
      ;
  }
  \%methods;
}

sub is_simple_attribute {
  my ($self, $name, $spec) = @_;
  # clearer doesn't have to be listed because it doesn't
  # affect whether defined/exists makes a difference
  !grep $spec->{$_},
    qw(lazy default builder coerce isa trigger predicate weak_ref);
}

sub is_simple_get {
  my ($self, $name, $spec) = @_;
  !($spec->{lazy} and ($spec->{default} or $spec->{builder}));
}

sub is_simple_set {
  my ($self, $name, $spec) = @_;
  !grep $spec->{$_}, qw(coerce isa trigger weak_ref);
}

sub has_eager_default {
  my ($self, $name, $spec) = @_;
  (!$spec->{lazy} and ($spec->{default} or $spec->{builder}));
}

sub _generate_get {
  my ($self, $name, $spec) = @_;
  my $simple = $self->_generate_simple_get('$_[0]', $name, $spec);
  if ($self->is_simple_get($name, $spec)) {
    $simple;
  } else {
    'do { '.$self->_generate_use_default(
      '$_[0]', $name, $spec,
      $self->_generate_simple_has('$_[0]', $name, $spec),
    ).'; '
    .($spec->{isa}
      ?($self->_generate_isa_check($name, $simple, $spec->{isa}).'; ')
      :''
    )
    .$simple.' }';
  }
}

sub _generate_simple_has {
  my ($self, $me, $name) = @_;
  "exists ${me}->{${\perlstring $name}}";
}

sub _generate_simple_clear {
  my ($self, $me, $name) = @_;
  "    delete ${me}->{${\perlstring $name}}\n"
}

sub generate_get_default {
  my $self = shift;
  $self->{captures} = {};
  my $code = $self->_generate_get_default(@_);
  ($code, delete $self->{captures});
}

sub _generate_use_default {
  my ($self, $me, $name, $spec, $test) = @_;
  my $get_value = $self->_generate_get_default($me, $name, $spec);
  if ($spec->{coerce}) {
    $get_value = $self->_generate_coerce(
      $name, $get_value,
      $spec->{coerce}
    )
  }
  $self->_generate_simple_set(
    $me, $name, $spec, $get_value
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
  my ($self, $name, $spec) = @_;
  if ($self->is_simple_set($name, $spec)) {
    $self->_generate_simple_set('$_[0]', $name, $spec, '$_[1]');
  } else {
    my ($coerce, $trigger, $isa_check) = @{$spec}{qw(coerce trigger isa)};
    my $simple = $self->_generate_simple_set('$self', $name, $spec, '$value');
    my $code = "do { my (\$self, \$value) = \@_;\n";
    if ($coerce) {
      $code .=
        "        \$value = "
        .$self->_generate_coerce($name, '$value', $coerce).";\n";
    }
    if ($isa_check) {
      $code .= 
        "        ".$self->_generate_isa_check($name, '$value', $isa_check).";\n";
    }
    if ($trigger) {
      my $fire = $self->_generate_trigger($name, '$self', '$value', $trigger);
      $code .=
        "        ".$simple.";\n        ".$fire.";\n"
        ."        \$value;\n";
    } else {
      $code .= "        ".$simple.";\n";
    }
    $code .= "      }";
    $code;
  }
}

sub generate_coerce {
  my $self = shift;
  $self->{captures} = {};
  my $code = $self->_generate_coerce(@_);
  ($code, delete $self->{captures});
}

sub _attr_desc {
  my ($name, $init_arg) = @_;
  return perlstring($name) if !defined($init_arg) or $init_arg eq $name;
  return perlstring($name).' (constructor argument: '.perlstring($init_arg).')';
}

sub _generate_coerce {
  my ($self, $name, $value, $coerce, $init_arg) = @_;
  $self->_generate_die_prefix(
    "coercion for ${\_attr_desc($name, $init_arg)} failed: ",
    $self->_generate_call_code($name, 'coerce', "${value}", $coerce)
  );
}
 
sub generate_trigger {
  my $self = shift;
  $self->{captures} = {};
  my $code = $self->_generate_trigger(@_);
  ($code, delete $self->{captures});
}

sub _generate_trigger {
  my ($self, $name, $obj, $value, $trigger) = @_;
  $self->_generate_call_code($name, 'trigger', "${obj}, ${value}", $trigger);
}

sub generate_isa_check {
  my ($self, @args) = @_;
  $self->{captures} = {};
  my $code = $self->_generate_isa_check(@args);
  ($code, delete $self->{captures});
}

sub _generate_die_prefix {
  my ($self, $prefix, $inside) = @_;
  "do {\n"
  .'  my $sig_die = $SIG{__DIE__} || sub { die $_[0] };'."\n"
  .'  local $SIG{__DIE__} = sub {'."\n"
  .'    $sig_die->(ref($_[0]) ? $_[0] : '.perlstring($prefix).'.$_[0]);'."\n"
  .'  };'."\n"
  .$inside
  ."}\n"
}

sub _generate_isa_check {
  my ($self, $name, $value, $check, $init_arg) = @_;
  $self->_generate_die_prefix(
    "isa check for ${\_attr_desc($name, $init_arg)} failed: ",
    $self->_generate_call_code($name, 'isa_check', $value, $check)
  );
}

sub _generate_call_code {
  my ($self, $name, $type, $values, $sub) = @_;
  if (my $quoted = quoted_from_sub($sub)) {
    my $code = $quoted->[1];
    if (my $captures = $quoted->[2]) {
      my $cap_name = qq{\$${type}_captures_for_${name}};
      $self->{captures}->{$cap_name} = \$captures;
      Sub::Quote::inlinify(
        $code, $values, Sub::Quote::capture_unroll($cap_name, $captures, 6), 1
      );
    } else {
      Sub::Quote::inlinify($code, $values, undef, 1);
    }
  } else {
    my $cap_name = qq{\$${type}_for_${name}};
    $self->{captures}->{$cap_name} = \$sub;
    "${cap_name}->(${values})";
  }
}

sub generate_populate_set {
  my $self = shift;
  $self->{captures} = {};
  my $code = $self->_generate_populate_set(@_);
  ($code, delete $self->{captures});
}

sub _generate_populate_set {
  my ($self, $me, $name, $spec, $source, $test, $init_arg) = @_;
  if ($self->has_eager_default($name, $spec)) {
    my $get_indent = ' ' x ($spec->{isa} ? 6 : 4);
    my $get_default = $self->_generate_get_default(
                        '$new', $_, $spec
                      );
    my $get_value = 
      defined($spec->{init_arg})
        ? "(\n${get_indent}  ${test}\n${get_indent}   ? ${source}\n${get_indent}   : "
            .$get_default
            ."\n${get_indent})"
        : $get_default;
    if ($spec->{coerce}) {
      $get_value = $self->_generate_coerce(
        $name, $get_value,
        $spec->{coerce}, $init_arg
      )
    }
    ($spec->{isa}
      ? "    {\n      my \$value = ".$get_value.";\n      "
        .$self->_generate_isa_check(
          $name, '$value', $spec->{isa}, $init_arg
        ).";\n"
        .'      '.$self->_generate_simple_set($me, $name, $spec, '$value').";\n"
        ."    }\n"
      : '    '.$self->_generate_simple_set($me, $name, $spec, $get_value).";\n"
    )
    .($spec->{trigger}
      ? '    '
        .$self->_generate_trigger(
          $name, $me, $self->_generate_simple_get($me, $name, $spec),
          $spec->{trigger}
        )." if ${test};\n"
      : ''
    );
  } else {
    "    if (${test}) {\n"
      .($spec->{coerce}
        ? "      $source = "
          .$self->_generate_coerce(
            $name, $source,
            $spec->{coerce}, $init_arg
          ).";\n"
        : ""
      )
      .($spec->{isa}
        ? "      "
          .$self->_generate_isa_check(
            $name, $source, $spec->{isa}, $init_arg
          ).";\n"
        : ""
      )
      ."      ".$self->_generate_simple_set($me, $name, $spec, $source).";\n"
      .($spec->{trigger}
        ? "      "
          .$self->_generate_trigger(
            $name, $me, $self->_generate_simple_get($me, $name, $spec),
            $spec->{trigger}
          ).";\n"
        : ""
      )
      ."    }\n";
  }
}

sub _generate_core_set {
  my ($self, $me, $name, $spec, $value) = @_;
  my $name_str = perlstring $name;
  "${me}->{${name_str}} = ${value}";
}

sub _generate_simple_set {
  my ($self, $me, $name, $spec, $value) = @_;
  my $name_str = perlstring $name;

  if ($spec->{weak_ref}) {
    $value = '$preserve = '.$value;
    my $simple = $self->_generate_core_set($me, $name, $spec, $value);
    require Scalar::Util;

    # Perl < 5.8.3 can't weaken refs to readonly vars
    # (e.g. string constants). This *can* be solved by:
    #
    #Internals::SetReadWrite($foo);
    #Scalar::Util::weaken ($foo);
    #Internals::SetReadOnly($foo);
    #
    # but requires XS and is just too damn crazy
    # so simply throw a better exception
    my $weak_simple = "my \$preserve; Scalar::Util::weaken(${simple}); no warnings 'void'; \$preserve";
    Moo::_Utils::lt_5_8_3() ? <<"EOC" : $weak_simple;

      my \$preserve;
      eval { Scalar::Util::weaken($simple); 1 }
        ? do { no warnings 'void'; \$preserve; }
        : do {
          if( \$@ =~ /Modification of a read-only value attempted/) {
            require Carp;
            Carp::croak( sprintf (
              'Reference to readonly value in "%s" can not be weakened on Perl < 5.8.3',
              $name_str,
            ) );
          } else {
            die \$@;
          }
        }
EOC
  } else {
    $self->_generate_core_set($me, $name, $spec, $value);
  }
}

sub _generate_getset {
  my ($self, $name, $spec) = @_;
  q{(@_ > 1}."\n      ? ".$self->_generate_set($name, $spec)
    ."\n      : ".$self->_generate_get($name, $spec)."\n    )";
}

sub _generate_delegation {
  my ($self, $asserter, $target, $args) = @_;
  my $arg_string = do {
    if (@$args) {
      # I could, I reckon, linearise out non-refs here using perlstring
      # plus something to check for numbers but I'm unsure if it's worth it
      $self->{captures}{'@curries'} = $args;
      '@curries, @_';
    } else {
      '@_';
    }
  };
  "shift->${asserter}->${target}(${arg_string});";
}

sub _generate_xs {
  my ($self, $type, $into, $name, $slot) = @_;
  Class::XSAccessor->import(
    class => $into,
    $type => { $name => $slot },
    replace => 1,
  );
  $into->can($name);
}

sub default_construction_string { '{}' }

1;
