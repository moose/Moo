use strict;
use warnings;

use Test::More;
use lib 't/lib';
use InlineModule (
  MooRoleWithAttrWithAutoclean => q{
    package MooRoleWithAttrWithAutoclean;
    use Moo::Role;
    # This causes the metaclass to be loaded and used before the 'has' fires
    # so Moo needs to blow it away again at that point so the attribute gets
    # added
    BEGIN { Class::MOP::class_of(__PACKAGE__)->get_method_list }

    has output_to => (
        is => 'ro',
        required => 1,
    );

    1;
  },
);

{
  package Bax;
  use Moose;

  with qw/
    MooRoleWithAttrWithAutoclean
  /;


  has '+output_to' => (
      required => 1,
  );
}

pass 'classes and roles built without error';

done_testing;
