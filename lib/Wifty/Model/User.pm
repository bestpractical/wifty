package Wifty::Model::User;

use Jifty::DBI::Schema;
use Wifty::Record schema {
    # column definitions
};

# import columns: name, email and email_confirmed
use Jifty::Plugin::User::Mixin::Model::User;
# import columns: password, auth_token
use Jifty::Plugin::Authentication::Password::Mixin::Model::User;

1;
