package # hide from PAUSE
    Moo::Conflicts;

use strict;
use warnings;

use Dist::CheckConflicts
    -dist      => 'Moo',
    -conflicts => {
        # enter conflicting downstream deps here, with the version indicating
        # the last *broken* version that *does not work*.
        'HTML::Restrict' => '2.1.5',
    },

    # these dists' ::Conflicts modules (if they exist) are also checked for
    # more incompatibilities -- should include all runtime prereqs here.
    -also => [ qw(
        Carp
        Class::Method::Modifiers
        strictures
        Module::Runtime
        Role::Tiny
        Devel::GlobalDestruction
    ) ],
;

1;
