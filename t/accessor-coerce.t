use strictures 1;
use Test::More;
use Test::Fatal;

sub run_for {
  my $class = shift;

  my $obj = $class->new(plus_three => 1);

  is($obj->plus_three, 4, "initial value set (${class})");

  $obj->plus_three(4);

  is($obj->plus_three, 7, 'Value changes after set');
}

{
  package Foo;

  use Moo;

  has plus_three => (
    is => 'rw',
    coerce => sub { $_[0] + 3 }
  );
}

run_for 'Foo';

{
  package Bar;

  use Sub::Quote;
  use Moo;

  has plus_three => (
    is => 'rw',
    coerce => quote_sub q{
      my ($x) = @_;
      $x + 3
    }
  );
}

run_for 'Bar';

{
  package Baz;

  use Sub::Quote;
  use Moo;

  has plus_three => (
    is => 'rw',
    coerce => quote_sub(
      q{
        my ($value) = @_;
        $value + $plus
      },
      { '$plus' => \3 }
    )
  );
}

run_for 'Baz';

{
  package Biff;

  use Sub::Quote;
  use Moo;

  has plus_three => (
    is => 'rw',
    coerce => quote_sub(
      q{
        die 'could not add three!'
      },
    )
  );
}

like exception { Biff->new(plus_three => 1) }, qr/could not add three!/, 'Exception properly thrown';

done_testing;
