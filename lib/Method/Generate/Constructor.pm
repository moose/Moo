package Method::Generate::Constructor;

use strictures 1;
use Sub::Quote;
use base qw(Class::Tiny::Object);

##{
##  use Method::Generate::Accessor;
##  my $gen = Method::Generate::Accessor->new;
##  $gen->generate_method(__PACKAGE__, $_, { is => 'ro' })
##    for qw(accessor_generator);
##}

sub generate_method {
  my ($self, $into, $name, $spec, $quote_opts) = @_;
  foreach my $no_init (grep !exists($spec->{$_}{init_arg}), keys %$spec) {
    $spec->{$no_init}{init_arg} = $no_init;
  }
  my $body = '    my $class = shift;'."\n";
  $body .= $self->_generate_args;
  $body .= $self->_check_required($spec);
  $body .= '    my $new = bless({}, $class);'."\n";
  $body .= $self->_assign_new($spec);
  $body .= '    return $new;'."\n";
  quote_sub
    "${into}::${name}" => $body,
    (ref($quote_opts) ? ({}, $quote_opts) : ())
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

1;
