use warnings;
use strict;

=head1 NAME

Wifty::Action::SendPasswordReminder

=cut

package Wifty::Action::SendPasswordReminder;
use base qw/Wifty::Action Jifty::Action/;

__PACKAGE__->mk_accessors(qw(user_object));

use Wifty::Model::User;

=head2 arguments

The field for C<SendPasswordReminder> is:

=over 4

=item address: the email address

=back

=cut

sub arguments {
    return (
        {
            address => {
                label     => 'email address',
                mandatory => 1,
            },
        }
    );

}

=head2 setup

Create an empty user object to work with

=cut

sub setup {
    my $self = shift;
    
    # Make a blank user object
    $self->user_object(Wifty::Model::User->new(current_user => Wifty::CurrentUser->superuser));
}

=head2 validate_address

Make sure there's actually an account by that name.

=cut

sub validate_address {
    my $self  = shift;
    my $email = shift;

    return $self->validation_error(address => "That doesn't look like an email address." )
      unless ( $email =~ /\S\@\S/ );

    $self->user_object(Wifty::Model::User->new(current_user => Wifty::CurrentUser->superuser));
    $self->user_object->load_by_cols( email => $email );
        return $self->validation_error(address => "It doesn't look like there's an account by that name.")
    unless ($self->user_object->id);

    return $self->validation_ok('address');
}

=head2 take_action

Send out a confirmation email giving a link to a password-reset form.

=cut

sub take_action {
    my $self = shift;
    Wifty::Notification::ConfirmLostPassword->new( to => $self->user_object )->send;
    return $self->result->message("A link to reset your password has been sent to your email account.");
}

1;
