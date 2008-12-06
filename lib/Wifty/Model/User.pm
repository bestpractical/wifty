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

    if ( $type eq 'read' ) {
        return 1;
    }

    return $self->SUPER::current_user_can($type, @_);
}

1;
