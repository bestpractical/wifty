package Wifty::Model::User::Schema;
use Jifty::DBI::Schema;

column name => 
    type is 'text',
    label is 'Name',
    is mandatory,
    is distinct;

column email =>
    type is 'text',
    label is 'Email address',
    is mandatory,
    is distinct;

column password =>,
    type is 'text',
    label is 'Password',
    render_as 'password';

column email_confirmed =>
    label is 'Email address confirmed?',
    type is 'boolean',
    since '0.0.10';

column auth_token => 
    type is 'text',
    render_as 'Password',
    since '0.0.15';



package Wifty::Model::User;
use base qw/Wifty::Record/;
use Wifty::Notification::ConfirmAddress;

sub since {'0.0.7'}

sub create {
    my $self = shift;
    my %args = (@_);
    my (@ret) = $self->SUPER::create(%args);

    if ($self->id and not $self->email_confirmed) {
        Wifty::Notification::ConfirmAddress->new( to => $self )->send;
    }
    return (@ret);
}


=head2 password_is STRING

Returns true if and only if the current user's password matches STRING

=cut


sub password_is {
    my $self = shift;
    my $string = shift;
    return 1 if ($self->_value('password') eq $string);
    return 0;
}

=head2 password

Never display a password

=cut

sub password {
    return undef;

}


sub current_user_can {
    my $self = shift;
    my $right = shift;
    my %args = (@_);
    return(1);
    if ($right eq 'read')  {

    } elsif ($right eq 'update') {

    }

    return $self->SUPER::current_user_can($right, %args);
}

=head2 auth_token

Returns the user's unique authentication token. If the user 
doesn't have one, sets one and returns it.

=cut


sub auth_token {
    my $self = shift;
    return undef unless ($self->current_user_can( read => 'auth_token'));
    my $value = $self->_value('auth_token') ;
    unless ($value) {
            my $digest =Digest::MD5->new();
            $digest->add(rand(100));
            $self->__set('auth_token' => $digest->b64digest);
            return $digest->b64digest;
    }

}

1;
