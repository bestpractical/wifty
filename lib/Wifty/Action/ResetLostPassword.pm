use warnings;
use strict;

=head1 NAME

Wifty::Action::ResetLostPassword - Confirm and reset a lost password

=head1 DESCRIPTION

This is the action run by the link in a user's email to confirm that their email
address is really theirs, when claiming that they lost their password.  


=cut

package Wifty::Action::ResetLostPassword;
use Wifty::Model::User;
use base qw/Wifty::Action/;

use Jifty::Param::Schema;
use Jifty::Action schema {

param password =>
    type is 'password',
    ! is sticky;

param password_confirm =>
    type is 'password',
    label is 'type your password again',
    ! is sticky;

};

=head2 take_action

Resets the password.

=cut

sub take_action {
    my $self = shift;
    my $u = Wifty::Model::User->new(current_user => Wifty::CurrentUser->superuser);
    $u->load_by_cols( email => Jifty->web->current_user->user_object->email );

    unless ($u) {
        $self->result->error( "You don't exist. I'm not sure how this happened. Really, really sorry. Please email us!");
    } 

    my $pass = $self->argument_value('password');
    my $pass_c = $self->argument_value('password_confirm');

    # Trying to set a password (ie, submitted the form)
    unless (defined $pass and defined $pass_c and length $pass and $pass eq $pass_c) {
        $self->result->error("It looks like you didn't enter the same password into both boxes. Give it another shot?");
        return;
    } 

    unless ($u->set_password($pass)) {
        $self->result->error("There was an error setting your password.");
        return;
    } 
    # Log in!
    $self->result->message( "Your password has been reset.  Welcome back." );
    Jifty->web->current_user(Wifty::CurrentUser->new(id => $u->id));
    return 1;

}

1;
