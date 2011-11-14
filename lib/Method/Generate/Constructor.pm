package Method::Generate::Constructor;

use strictures 1;
use Sub::Quote;
use base qw(Moo::Object);
use Sub::Defer;
use B 'perlstring';

sub register_attribute_specs {
  my ($self, %spec) = @_;
  @{$self->{attribute_specs}||={}}{keys %spec} = values %spec;
  $self;
}

sub all_attribute_specs {
  $_[0]->{attribute_specs}
}

sub accessor_generator {
  $_[0]->{accessor_generator}
}

sub construction_string {
  my ($self) = @_;
  $self->{construction_string} or 'bless({}, $class);'
}

sub install_delayed {
  my ($self) = @_;
  my $package = $self->{package};
  defer_sub "${package}::new" => sub {
    unquote_sub $self->generate_method(
      $package, 'new', $self->{attribute_specs}, { no_install => 1 }
    )
  };
  $self;
}

sub generate_method {
  my ($self, $into, $name, $spec, $quote_opts) = @_;
  foreach my $no_init (grep !exists($spec->{$_}{init_arg}), keys %$spec) {
    $spec->{$no_init}{init_arg} = $no_init;
  }
  local $self->{captures} = {};
  my $body = '    my $class = shift;'."\n"
            .'    $class = ref($class) if ref($class);'."\n";
  $body .= $self->_handle_subconstructor($into, $name);
  my $into_buildargs = $into->can('BUILDARGS');
  if ( $into_buildargs && $into_buildargs != \&Moo::Object::BUILDARGS ) {
      $body .= $self->_generate_args_via_buildargs;
  } else {
      $body .= $self->_generate_args;
  }
  $body .= $self->_check_required($spec);
  $body .= '    my $new = '.$self->construction_string.";\n";
  $body .= $self->_assign_new($spec);
  if ($into->can('BUILD')) {
    { local $@; require Method::Generate::BuildAll; }
    $body .= Method::Generate::BuildAll->new->buildall_body_for(
      $into, '$new', '$args'
    );
  }
  $body .= '    return $new;'."\n";
  if ($into->can('DEMOLISH')) {
    { local $@; require Method::Generate::DemolishAll; }
    Method::Generate::DemolishAll->new->generate_method($into);
  }
  quote_sub
    "${into}::${name}" => $body,
    $self->{captures}, $quote_opts||{}
  ;
}

sub _handle_subconstructor {
  my ($self, $into, $name) = @_;
  if (my $gen = $self->{subconstructor_generator}) {
    '    if ($class ne '.perlstring($into).') {'."\n".
    '      '.$gen.";\n".
    '      return $class->'.$name.'(@_)'.";\n".
    '    }'."\n";
  } else {
    ''
  }
}

sub _cap_call {
  my ($self, $code, $captures) = @_;
  @{$self->{captures}}{keys %$captures} = values %$captures if $captures;
  $code;
}

sub _generate_args_via_buildargs {
  my ($self) = @_;
  q{    my $args = $class->BUILDARGS(@_);}."\n";
}

# inlined from Moo::Object - update that first.
sub _generate_args {
  my ($self) = @_;
  return <<'_EOA';
    my $args;
    if ( scalar @_ == 1 ) {
        unless ( defined $_[0] && ref $_[0] eq 'HASH' ) {
            die "Single parameters to new() must be a HASH ref"
                ." data => ". $_[0] ."\n";
        }
        $args = { %{ $_[0] } };
    }
    elsif ( @_ % 2 ) {
        die "The new() method for $class expects a hash reference or a key/value list."
                . " You passed an odd number of arguments\n";
    }
    else {
        $args = {@_};
    }
_EOA

}

sub _assign_new {
  my ($self, $spec) = @_;
  my (@init, @slots, %test);
  my $ag = $self->accessor_generator;
  NAME: foreach my $name (sort keys %$spec) {
    my $attr_spec = $spec->{$name};
    unless ($ag->is_simple_attribute($name, $attr_spec)) {
      next NAME unless defined($attr_spec->{init_arg})
                         or $ag->has_eager_default($name, $attr_spec);
      $test{$name} = $attr_spec->{init_arg};
      next NAME;
    }
    next NAME unless defined(my $i = $attr_spec->{init_arg});
    push @init, $i;
    push @slots, $name;
  }
  return '' unless @init or %test;
  join '', (
    @init
      ? '    '.$self->_cap_call($ag->generate_multi_set(
          '$new', [ @slots ], '@{$args}{qw('.join(' ',@init).')}'
        )).";\n"
      : ''
  ), map {
    my $arg_key = perlstring($test{$_});
    my $test = "exists \$args->{$arg_key}";
    my $source = "\$args->{$arg_key}";
    my $attr_spec = $spec->{$_};
    $self->_cap_call($ag->generate_populate_set(
      '$new', $_, $attr_spec, $source, $test
    ));
  } sort keys %test;
}

sub _check_required {
  my ($self, $spec) = @_;
  my @required_init =
    map $spec->{$_}{init_arg},
      grep $spec->{$_}{required},
        sort keys %$spec;
  return '' unless @required_init;
  '    if (my @missing = grep !exists $args->{$_}, qw('
    .join(' ',@required_init).')) {'."\n"
    .q{      die "Missing required arguments: ".join(', ', sort @missing);}."\n"
    ."    }\n";
}

sub _check_isa {
  my ($self, $spec) = @_;
  my $acc = $self->accessor_generator;
  my $captures = $self->{captures};
  my $check = '';
  foreach my $name (sort keys %$spec) {
    my ($init, $isa) = @{$spec->{$name}}{qw(init_arg isa)};
    next unless $init and $isa;
    my $init_str = perlstring($init);
    my ($code, $add_captures) = $acc->generate_isa_check(
      $name, "\$args->{${init_str}}", $isa
    );
    @{$captures}{keys %$add_captures} = values %$add_captures;
    $check .= "    ${code}".(
      (not($spec->{lazy}) and ($spec->{default} or $spec->{builder})
        ? ";\n"
        : "if exists \$args->{${init_str}};\n"
      )
    );
  }
  return $check;
}

sub _fire_triggers {
  my ($self, $spec) = @_;
  my $acc = $self->accessor_generator;
  my $captures = $self->{captures};
  my $fire = '';
  foreach my $name (sort keys %$spec) {
    my ($init, $trigger) = @{$spec->{$name}}{qw(init_arg trigger)};
    next unless $init && $trigger;
    my ($code, $add_captures) = $acc->generate_trigger(
      $name, '$new', $acc->generate_simple_get('$new', $name), $trigger
    );
    @{$captures}{keys %$add_captures} = values %$add_captures;
    $fire .= "    ${code} if exists \$args->{${\perlstring $init}};\n";
  }
  return $fire;
}

1;
