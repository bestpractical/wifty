package Wifty::Dispatcher;
use Jifty::Dispatcher -base;

# Generic restrictions
under '/', run {
    Jifty->api->deny('ConfirmEmail');
};

# Default page
on '/', run {
    redirect( '/view/HomePage');
};

# Create a page
on '/create/*', run {
     set page => $1;
     set action => Jifty->web->new_action( class => 'CreatePage' );

     my $p = Wifty::Model::Page->new();
     if($p->current_user_can('create')) {
         show("/create");
     } else {
         show("/no_such_page");
     }
};

# View or edit a page
on qr{^/(view|edit)/(.*)}, run {
    my ( $name, $rev );
    my $page_name = $1;
    if ( $2 =~ qr{^(.*?)/?(\d*?)$} ) {
        $name = $1;
        $rev  = $2;
    }
    my $page = Wifty::Model::Page->new();
    $page->load_by_cols( name => $name );
    Jifty->web->redirect( '/create/' . $name ) unless ( $page->id );
    my $revision = Wifty::Model::Revision->new();
    $revision->load_by_cols( page => $page->id, id => $rev ) if ($rev);
    set page => $page;
    set revision => $revision;
    my $viewer = Jifty->web->new_action( class => 'UpdatePage', record => $page );
    if($rev) {
        $viewer->argument_value(content => $revision->content);
    }
    set viewer => $viewer;
    show("/$page_name");
};

# View page history
on 'history/*', run {
    my $name = $1;
    my $page = Wifty::Model::Page->new();
    $page->load_by_cols( name => $name );
    redirect( '/create/' . $name ) unless ( $page->id );

    my $revisions = $page->revisions;
    $revisions->order_by( column => 'id', order => 'desc');

    set page => $page;
    set revisions => $revisions;
    show('/history');
};

# List pages
on 'pages', run {
    my $pages = Wifty::Model::PageCollection->new();
    $pages->unlimit();
    set pages => $pages;
};

# Show recent edits
on 'recent', run {
    my $then = DateTime->from_epoch( epoch => ( time - ( 86400 * 7 ) ) );
    my $pages = Wifty::Model::PageCollection->new();
    $pages->limit(
        column   => 'updated',
        operator => '>',
        value    => $then->ymd
    );
    $pages->order_by( column => 'updated', order => 'desc' );
    set pages => $pages;
};


1;
