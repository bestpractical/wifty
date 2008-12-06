package Wifty::Model::User;

use Jifty::DBI::Schema;
use Wifty::Record schema {
    # column definitions
};

# import columns: name, email and email_confirmed
use Jifty::Plugin::User::Mixin::Model::User;
# import columns: password, auth_token
use Jifty::Plugin::Authentication::Password::Mixin::Model::User;

sub friendly_name {
    my $self = shift;
    return _('Anonymous') unless $self->id;
    return $self->name;
}

sub current_user_can {
    my $self = shift;
    my $type = shift;
    my $column = shift;

    if ( $type eq 'read' ) {
        return 1 if $column eq 'name';
        my $cu = $self->current_user;
        return 1 if $self->id && ($cu->id||0) == $self->id;
    }

    return $self->SUPER::current_user_can($type, $column, @_);
}

1;
