package ExampleMooRoleWithAttribute;;
use Moo::Role;
# Note that autoclean here is the key bit!
# It causes the metaclass to be loaded and used before the 'has' fires
# so Moo needs to blow it away again at that point so the attribute gets
# added
use namespace::autoclean;

has output_to => (
    is => 'ro',
    required => 1,
);

1;

