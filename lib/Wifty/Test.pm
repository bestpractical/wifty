use warnings;
use strict;

package Wifty::Test;
use base qw/Jifty::Test/;

=head2 setup

Set up for testing. Calls L<Jifty::Test/setup> and L</setup_db>.

=cut

sub setup {
    my $class = shift;
    $class->SUPER::setup;
    $class->setup_db;
}

=head2 setup_db

Add two users to the database:

Some User <someuser@localhost>, password 'sekrit'
Other User <otheruser@localhost>, password 'motdepasse'

This should be kept in sync with C<t/0-test-database>.

=cut

sub setup_db {
    my $class = shift;

    my $admin = Wifty::CurrentUser->superuser;

    my $someuser = Wifty::Model::User->new(current_user => $admin);
    $someuser->create(
        name            => 'Some User',
        email           => 'someuser@localhost',
        password        => 'sekrit',
        email_confirmed => 1,
       );

    my $otheruser = Wifty::Model::User->new(current_user => $admin);
    $otheruser->create(
        name            => 'Other User',
        email           => 'otheruser@localhost',
        password        => 'motdepasse',
        email_confirmed => 1,
       );

}

1;
