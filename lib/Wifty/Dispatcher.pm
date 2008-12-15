package Wifty::Dispatcher;
use Jifty::Dispatcher -base;

# Generic restrictions
under '/', run {
    Jifty->api->deny('ConfirmEmail');
};

before '*', run {
    my $top = Jifty->web->navigation;
    $top->child( Home   => url => "/",                 label => _("Home") );
    $top->child( Recent => url => "/recent/changes",   label => _("Recent Changes") );
    $top->child( New    => url => "/recent/additions", label => _("New") );
    $top->child( Search => url => "/search",           label => _("Search") );
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
    my $page_name = $1;
    my ( $name, $rev ) = ($2 =~ qr{^(.*?)(?:/(\d+))?$});

    my $page = Wifty::Model::Page->new();
    $page->load_by_cols( name => $name );
    Jifty->web->redirect( '/create/' . $name )
        unless $page->id;

    $rev = $page->revision($rev);

    setup_page_nav($page_name, $page, $rev);

    set page => $page;
    set revision => $rev || new Wifty::Model::Revision;
    set viewer => $rev? $rev->viewer: $page->viewer;
    show("/$page_name");
};

# View page history
on 'history/*', run {
    my $name = $1;
    my $page = Wifty::Model::Page->new();
    $page->load_by_cols( name => $name );
    redirect( '/create/' . $name ) unless ( $page->id );

    setup_page_nav('view', $page);

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

on 'search', run {
    my $search = Jifty->web->response->result('search');
    my $collection = undef;
    if($search) {
        $collection = $search->content('search');
    }
    my $action =  Jifty->web->new_action(class => 'SearchPage', moniker => 'search');
    $action->sticky_on_success(1);

    set search => $action;
    set pages => $collection;
};

# Show recent

# backwards compat
on 'recent' => run { redirect('/recent/changes') };
on qr{^/recent/(changes|additions)}, run {
    my $type = $1;
    if ( $type eq 'changes' ) {
        set title => _('Updated this week');
        set pages => Wifty::Model::PageCollection->recently_updated;
    } elsif ( $type eq 'additions' ) {
        set title => _('Created this week');
        set pages => Wifty::Model::PageCollection->recently_created;
    }
    set type => $type;
    show('/recent');
};

on 'feeds/atom/recent' => run { redirect('/feeds/atom/recent/changes/headlines') };
on qr{^/feeds/atom/recent/(changes|additions)(?:/(full|headlines|diff))?$} => run {
    my $wikiname = Jifty->config->app('WikiName');
    my $show = $1;
    my $show_as = $2 || 'headlines';
    my ($pages, $title);
    if ( $show eq 'changes' ) {
        $pages = Wifty::Model::PageCollection->recently_updated;
        $title = $wikiname
            ? _('Recently changed pages on %1 wiki', $wikiname)
            : _('Recently changed pages on some wiki');
    } else {
        $pages = Wifty::Model::PageCollection->recently_created;
        $title = $wikiname
            ? _('Recently added pages on %1 wiki', $wikiname)
            : _('Recently added pages on some wiki');
    }
    set( title => $title ); set( pages => $pages ); set( show_as => $show_as );
    show('/feeds/atom/pages');
};

sub setup_page_nav {
    my ($prefix, $page, $rev) = @_;

    my $name = $page->name;

    my $subpath = $name;
    $subpath .= '/'. $rev->id if $rev;
    my $top = Jifty->web->page_navigation;
    $top->child( View => url => '/view/'. $subpath, label => _('View') );
    $top->child( Edit => url => '/edit/'. $subpath, label => _('Edit') );
    if ( my $prev = ($rev? $rev : $page->revisions->last)->previous ) {
        $top->child(
            Older => label => _('Previous Version'),
            url => join '/', '', $prefix, $name, $prev->id
        );
    }
    $top->child(
        History => label => _('History'),
        url => '/history/'. $name
    );
    if ( $rev and my $next = $rev->next ) {
        $top->child(
            Newer => label => _('Next Version'),
            url => join '/',  '', $prefix, $name, $next->id
        );
        $top->child(
            Latest => label => _('Latest'),
            url => join '/', '', $prefix, $name
        );
    }
}

1;
