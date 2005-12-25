use warnings;
use strict;

=head1 NAME

Wifty::Action::ResendConfirmation

=cut

package Wifty::Action::ResendConfirmation;
use base qw/Wifty::Action Jifty::Action/;

__PACKAGE__->mk_accessors(qw(user_object));

use Wifty::Model::User;

=head2 arguments

The field for C<ResendConfirmation> is:

=over 4

=item address: the email address

=back

=cut

sub arguments {
    return ( { address => { label     => 'email address', mandatory => 1, default_value => "", }, });
}

=head2 setup

Create an empty user object to work with

=cut

sub setup {
    my $self = shift;
    
    $self->user_object(Wifty::Model::User->new(current_user => Wifty::CurrentUser->superuser));
}

=head2 validate_address

Make sure their email address is an unconfirmed user.

=cut

sub validate_address {
    my $self  = shift;
    my $email = shift;

    return $self->validation_error(address => "That doesn't look like an email address." ) unless ( $email =~ /\S\@\S/ );

    $self->user_object(Wifty::Model::User->new(current_user => Wifty::CurrentUser->superuser));
    $self->user_object->load_by_cols( email => $email );
    return $self->validation_error(address => "It doesn't look like there's an account by that name.") unless ($self->user_object->id);

    return $self->validation_error(address => "It looks like you're already confirmed.") if ($self->user_object->email_confirmed);

    return $self->validation_ok('address');
}

=head2 take_action

Create a new unconfirmed user and send out a confirmation email.

=cut

sub take_action {
    my $self = shift;
    Wifty::Notification::ConfirmAddress->new( to => $self->user_object )->send;
    return $self->result->message("Confirmation resent.");
}

1;