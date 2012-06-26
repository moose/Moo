package ClassicObject;

sub new {
    my ($class, %args) = @_;
    bless \%args, 'ClassicObject';
}

sub connect { 'a' }

1;
