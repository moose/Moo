package withautoclean::Class;
use Moo;

with 'withautoclean::R1';

before _clear_ctx => sub {
};

1;

