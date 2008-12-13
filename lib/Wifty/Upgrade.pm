use strict;
use warnings;

package Wifty::Upgrade;

use base qw(Jifty::Upgrade);
use Jifty::Upgrade qw( since rename );

since '0.0.21' => sub {
    my $pages = Wifty::Model::PageCollection->new(
        current_user => Jifty->app_class('CurrentUser')->superuser
    );
    $pages->unlimit;

    while ( my $page = $pages->next ) {
        my $first_rev = $page->revisions->first;
        my ($status, $msg) = $page->set_created( $first_rev? $first_rev->created : $page->updated );
        Jifty->log->error("Couldn't set created:". $msg) unless $status;
        ($status, $msg) = $page->set_created_by( $first_rev? $first_rev->created_by : $page->updated_by );
        Jifty->log->error("Couldn't set created_by:". $msg) unless $status;
    }
};

1;
