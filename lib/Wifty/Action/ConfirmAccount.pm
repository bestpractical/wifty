use warnings;
use strict;

=head1 NAME

Wifty::Action::ConfirmEmail - Confirm a user's email address

=head1 DESCRIPTION

This is the link in a user's email to confirm that their email
email is really theirs.  It is not really meant to be rendered on any
web page, but is used by the confirmation notification.

Note that the use of C<auth_token> here is insecure and wrong!
(XXX TODO FIXME) If an attacker knew the token calculation algorithm (including
the non-random salt), they could easily do email confirmation without needed
to actually have access to the email account, since the algorithm only depends on
the email address, requested password, and non-random salt.

=cut

package Wifty::Action::ConfirmEmail;
use base qw/Wifty::Action Jifty::Action/;

use Wifty::Model::User;


=head2 actions

A null sub, because the superclass wants to make sure we fill in actions

=cut

sub actions {}

=head2 take_action

Set their confirmed status.

=cut

sub take_action {
    my $self = shift;
    my $u = Wifty::Model::User->new(current_user => Wifty::CurrentUser->superuser);
    $u->load_by_cols( email => Jifty->web->current_user->user_object->email );

    if ($u->email_confirmed) {
        $self->result->error(email => "You have already confirmed your account.");
        $self->result->success(1);  # but the action is still a success
    }

    $u->set_email_confirmed('1');

    # Set up our login message
    $self->result->message( "Welcome to Wifty, " . $u->name . ". Your email address has now been confirmed." );

    # Actually do the login thing.
    Jifty->web->current_user(Wifty::CurrentUser->new(id => $u->id));
    return 1;
}

1;
