use strict;
use warnings;
use lib 't/lib';

use Test::More;
use CaptureException;

sub run_for {
  my $class = shift;

  my $obj = $class->new(plus_three => 1);

  is($obj->plus_three, 4, "initial value set (${class})");

  $obj->plus_three(4);

  is($obj->plus_three, 7, 'Value changes after set');
}

sub run_with_default_for {
  my $class = shift;

  my $obj = $class->new();

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

like exception { Biff->new(plus_three => 1) }, qr/coercion for "plus_three" failed: could not add three!/, 'Exception properly thrown';

{
  package Foo2;

  use Moo;

  has plus_three => (
    is => 'rw',
    default => sub { 1 },
    coerce => sub { $_[0] + 3 }
  );
}

run_with_default_for 'Foo2';

{
  package Bar2;

  use Sub::Quote;
  use Moo;

  has plus_three => (
    is => 'rw',
    default => sub { 1 },
    coerce => quote_sub q{
      my ($x) = @_;
      $x + 3
    }
  );
}

run_with_default_for 'Bar2';

{
  package Baz2;

  use Sub::Quote;
  use Moo;

  has plus_three => (
    is => 'rw',
    default => sub { 1 },
    coerce => quote_sub(
      q{
        my ($value) = @_;
        $value + $plus
      },
      { '$plus' => \3 }
    )
  );
}

run_with_default_for 'Baz2';

{
  package Biff2;

  use Sub::Quote;
  use Moo;

  has plus_three => (
    is => 'rw',
    default => sub { 1 },
    coerce => quote_sub(
      q{
        die 'could not add three!'
      },
    )
  );
}

like exception { Biff2->new() }, qr/could not add three!/, 'Exception properly thrown';

{
  package Foo3;

  use Moo;

  has plus_three => (
    is => 'rw',
    default => sub { 1 },
    coerce => sub { $_[0] + 3 },
    lazy => 1,
  );
}

run_with_default_for 'Foo3';

{
  package Bar3;

  use Sub::Quote;
  use Moo;

  has plus_three => (
    is => 'rw',
    default => sub { 1 },
    coerce => quote_sub(q{
      my ($x) = @_;
      $x + 3
    }),
    lazy => 1,
  );
}

run_with_default_for 'Bar3';

{
  package CoerceWriter;
  use Moo;
  has attr => (
    is     => 'rwp',
    coerce => sub { die 'triggered' },
  );
}
like exception { CoerceWriter->new->_set_attr( 4 ) },
  qr/triggered/, "coerce triggered via writer";

done_testing;
