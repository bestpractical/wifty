use warnings;
use strict;

package Wifty::View::Users;
use Jifty::View::Declare -base;

template stats => page {
    my ($user) = get('user');
    page_title is _('Statistics of user %1', $user->friendly_name );

    set(type => 'updated'); show('recently');
    set(type => 'created'); show('recently');
};

private template recently => sub {
    my ($user, $type) = get('user', 'type');
    
    my $method = 'recently_'. $type;
    my $pages = Wifty::Model::PageCollection->$method;
    $pages->limit( column => $type .'_by', value => $user->id );

    h1 { $type eq 'updated'? _('Recenly updated') : _('Recently created') };
    set(
        pages => $pages,
        id => 'recent-user-updates',
        hide => [$type],
    );
    show('/page_list');
};

1;
