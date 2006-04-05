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
     show("/create");
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
    set viewer => Jifty->web->new_action( class => 'UpdatePage', record => $page );
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

# Sign up for an account
on 'signup', run {
    redirect('/') if ( Jifty->web->current_user->id );
    set 'action' =>
        Jifty->web->new_action( class => 'Signup', moniker => 'signupbox' );

    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );

};

# Login
on 'login', run {
    set 'action' =>
        Jifty->web->new_action( class => 'Login', moniker => 'loginbox' );
    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );
};

# Log out
before 'logout', run {
    Jifty->web->request->add_action(
        moniker => 'logout',
        class   => 'Wifty::Action::Logout'
    );
};


## LetMes
before qr'^/let/(.*)' => run {
    Jifty->api->deny(qr/^Wifty::Dispatcher/);

    my $let_me = Jifty::LetMe->new();
    $let_me->from_token($1);
    redirect '/error/let_me/invalid_token' unless $let_me->validate;

    Jifty->web->temporary_current_user($let_me->validated_current_user);

    my %args = %{$let_me->args};
    set $_ => $args{$_} for keys %args;
    set let_me => $let_me;
};

on qr'^/let/', => run {
    my $let_me = get 'let_me';
    show '/let/' . $let_me->path;
};


1;
