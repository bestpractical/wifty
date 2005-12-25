use warnings;
use strict;

=head1 NAME

Wifty::Action::Logout

=cut

package Wifty::Action::Logout;
use base qw/Wifty::Action Jifty::Action/;

=head2 arguments

Return the email and password form fields

=cut

sub arguments { 
    return( { });
}

=head2 take_action

Nuke the current user object

=cut

sub take_action {
    my $self = shift;
    Jifty->web->current_user(undef);
    return 1;
}

1;
