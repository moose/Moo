package Method::Generate::Constructor;

use strictures 1;
use Sub::Quote;
use base qw(Class::Tiny::Object);
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
  my $body = '    my $class = shift;'."\n";
  $body .= $self->_generate_args;
  $body .= $self->_check_required($spec);
  $body .= '    my $new = bless({}, $class);'."\n";
  $body .= $self->_assign_new($spec);
  $body .= $self->_fire_triggers($spec);
  $body .= '    return $new;'."\n";
  quote_sub
    "${into}::${name}" => $body,
    $self->{captures}, $quote_opts||{}
  ;
}

sub _generate_args {
  my ($self) = @_;
  q{    my $args = ref($_[0]) eq 'HASH' ? $_[0] : { @_ };}."\n";
}

sub _assign_new {
  my ($self, $spec) = @_;
  my (@init, @slots);
  NAME: foreach my $name (keys %$spec) {
    my $attr_spec = $spec->{$name};
    push @init, do {
      next NAME unless defined(my $i = $attr_spec->{init_arg});
      $i;
    };
    push @slots, $name;
  }
  return '' unless @init;
  '    @{$new}{qw('.join(' ',@slots).')} = @{$args}{qw('.join(' ',@init).')};'
    ."\n";
}

sub _check_required {
  my ($self, $spec) = @_;
  my @required_init =
    map $spec->{$_}{init_arg},
      grep $spec->{$_}{required},
        keys %$spec;
  return '' unless @required_init;
  '    if (my @missing = grep !exists $args->{$_}, qw('
    .join(' ',@required_init).')) {'."\n"
    .q{      die "Missing required arguments: ".join(', ', sort @missing);}."\n"
    ."    }\n";
}

sub _fire_triggers {
  my ($self, $spec) = @_;
  my @fire = map {
    [ $_, $spec->{$_}{init_arg}, $spec->{$_}{trigger} ]
  } grep { $spec->{$_}{init_arg} && $spec->{$_}{trigger} } keys %$spec;
  my $acc = $self->accessor_generator;
  my $captures = $self->{captures};
  my $fire = '';
  foreach my $name (keys %$spec) {
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
