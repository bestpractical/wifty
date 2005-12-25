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



package Wifty::Model::User;
use base qw/Wifty::Record/;

sub since {'0.0.7'}

sub create {
    my $self = shift;
    my %args = (@_);
    my ($id) = $self->SUPER::create(%args);
    return($id);
}

1;
