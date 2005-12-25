package Wifty::Model::User::Schema;
use Jifty::DBI::Schema;

column name => 
    type is 'text',
    is mandatory,
    is distinct;

column email =>
    type is 'text',
    is mandatory,
    is distinct;

column password =>,
    type is 'text',
    render_as 'password';

column email_confirmed =>
    type is 'boolean',
    since '0.0.10';


package Wifty::Model::User;
use base qw/Wifty::Record/;

sub since {'0.0.7'}

sub create {
    my $self = shift;
    my %args = (@_);
    my ($id) = $self->SUPER::create(%args);
    return($id);
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

    if ($right eq 'read')  {

    } elsif ($right eq 'write') {

    }

    return $self->SUPER::current_user_can($right, %args);
}


1;
