package Role::Tiny::With;

use strict;
use warnings FATAL => 'all';

use Exporter 'import';
our @EXPORT = qw( with );

sub with {
    my $target = caller;
    Role::Tiny->apply_role_to_package($target, @_)
}

1;

=head1 NAME

Role::Tiny::With - Neat interface for consumers of Role::Tiny roles

=head1 SYNOPSIS

 package Some::Class;

 use Role::Tiny::With;

 with 'Some::Role';

 # The role is now mixed in

=head1 DESCRIPTION

C<Role::Tiny> is a minimalist role composition tool.  C<Role::Tiny::With>
provides a C<with> function to compose such roles.

=head1 AUTHORS

See L<Moo> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Moo> for the copyright and license.

=cut


