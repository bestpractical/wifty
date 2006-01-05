package Wifty::Dispatcher;
use Jifty::Dispatcher -base;

on '/', run {
    redirect( '/view/HomePage');
};

under '/create/*', run {
     set page => $1;
     set action => Jifty->web->new_action( class => 'CreatePage' );
};


under ['view/*', 'edit/*'], run {
    my ( $name, $rev );
    if ( $1 =~ qr{^(.*?)/?(\d*?)$} ) {
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
    set viewer => Jifty->web->new_action( class => 'UpdatePage', record => $page );
};

under 'history/*', run {
    my $name = $1;
    my $page = Wifty::Model::Page->new();
    $page->load_by_cols( name => $name );
    redirect( '/create/' . $name ) unless ( $page->id );

    my $revisions = $page->revisions;
    $revisions->order_by( column => 'id', order => 'desc');

    set page => $page;
    set revisions => $revisions;

};


on 'pages', run {
    my $pages = Wifty::Model::PageCollection->new();
    $pages->unlimit();
    set pages => $pages;
};

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

on 'signup', run {
    redirect('/') if ( Jifty->web->current_user->id );
    set 'action' =>
        Jifty->web->new_action( class => 'Signup', moniker => 'signupbox' );

    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );

};

on 'login', run {
    set 'action' =>
        Jifty->web->new_action( class => 'Login', moniker => 'loginbox' );
    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );

};

on 'logout', run {
    Jifty->web->request->add_action(
        moniker => 'logout',
        class   => 'Wifty::Action::Logout'
    );
};

    
1;
