use warnings;
use strict;

package Wifty::Notification::ConfirmAddress;
use base qw/Wifty::Notification/;

=head1 NAME

Hiveminder::Notification::ConfirmAddress

=head1 ARGUMENTS

C<to>, a L<Wifty::Model::User> whose address we are confirming.

=cut

=head2 setup

Sets up the fields of the message.

=cut

sub setup {
    my $self = shift;

    unless (UNIVERSAL::isa($self->to, "Wifty::Model::User")) {
	$self->log->error((ref $self) . " called with invalid user argument");
	return;
    } 
   

    my $letme = Jifty::LetMe->new();
    $letme->email($self->to->email);
    $letme->path('confirm_email'); 
    my $confirm_url = $letme->as_url;

    $self->subject( "Welcome to Wifty!" ); 
    

    $self->body(<<"END_BODY");

You're getting this message because you (or somebody claiming to be you)
signed up for a Wiki running Wifty.

Before you can use Wifty, we need to make sure that we got your email
address right.  Click on the link below to get started:

$confirm_url

END_BODY
}

1;
