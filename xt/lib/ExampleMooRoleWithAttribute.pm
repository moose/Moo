package ExampleMooRoleWithAttribute;;
use Moo::Role;
# Note that autoclean here is the key bit!
use namespace::autoclean;

has output_to => (
    is => 'ro',
    required => 1,
);

1;

