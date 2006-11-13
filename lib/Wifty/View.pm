use warnings;
use strict;


=head1 NAME

Wifty::View

=head1 DESCRIPTION

This code is only useful on the new Jifty "Declarative tempaltes" branch. It shouldn't get in the way 
if you're running a traditional (0.610 or before) Jifty.

=cut

package Wifty::View;
use base qw/Jifty::View::Declare::Templates/;
# includes my application's plugins' View libraries as superclasses.
use Template::Declare::Tags;
use Jifty::View::Declare::Templates;

private template page_list => sub {

    # actually creates: sub _jifty_ui_template_page_list
    #
    my (  $pages, $id ) = get(qw(pages id));
    with( id => $id, class => "pagelist" ), dl {

        while ( my $page = $pages->next ) {
            dt {
                hyperlink(
                    label => $page->name,
                    url   => '/view/' . $page->name
                );
            };
            dd {
                outs( $page->updated );
                outs(
                    ' - ('
                        . (
                          $page->updated_by->id
                        ? $page->updated_by->name
                        : _('Anonymous')
                        )
                        . ')'
                );
            };
        }
    };
};

private template nav => sub {
    my $top  = Jifty->web->navigation;
    $top->child( Home => url => "/", sort_order => 1 );
    $top->child(
        Recent  =>
            url => "/recent",
        label      => "Recent Changes",
        sort_order => 2
    );
    $top->child(
        Search  =>
            url => "/search",
        label      => "Search",
        sort_order => 3
    );

    if ( Jifty->config->framework('AdminMode') ) {
        $top->child(
            Administration =>
                url        => "/__jifty/admin/",
            sort_order => 998
        );
        $top->child(
            OnlineDocs =>
                url    => "/__jifty/online_docs/",
            label      => 'Online docs',
            sort_order => 999
        );
    }

};

private template page_nav => sub {
    my %args = (page => 'HomePage', rev => undef, @_);
    my $page = $args{'page'};
    my $rev = $args{'rev'};
    
    $page ||= 'HomePage';
    my $subpath = $page . ( $rev ? "/$rev" : '' );
    my $top     = Jifty->web->page_navigation;

    my $page_obj = Wifty::Model::Page->new();
    $page_obj->load_by_cols( name => $page );

    $top->child( View => url => '/view/' . $subpath );
    $top->child( Edit => url => '/edit/' . $subpath );
    $top->child( History => url => '/history/' . $page );
    $top->child( Latest => url => '/view/' . $page ) if ($rev);

};

private template wrapper => sub {
    # it's actually called with args.
    my ($args, $coderef ) = (@_);
    my $title    = $args->{title};
    my $id       = $args->{id};
    my $wikiname = Jifty->config->app('WikiName') || "Wifty";

    show('nav');
    show( 'header', title => $args->{'title'}, wikiname => $wikiname );

    with( id => $args->{id} ), body {

        if ( Jifty->config->framework('AdminMode') ) {
            with( class => 'warning admin_mode' ), div {
                _('Alert') . ":"
                    . tangent(
                    label => _('Administration mode is enabled'),
                    url   => '/__jifty/admin/'
                    )
                    . ".";
                }
        }
        with( id => 'logo' ), div {
            Jifty->config->app('Logo')
                ? '<img src="' . Jifty->config->app('Logo') . '" alt="" />'
                : '';
        };
        with( id => 'header' ), div {
            with( id => 'wikiheader' ), div {
                with( id => "wikiname" ), h1 {
                    hyperlink( url => "/", label => _($wikiname) );
                };
                outs(Jifty->web->navigation->render_as_menu);
                show('search_box');

            };
            with( id => 'pageheader' ), div {
                with( id => "pagename" ), h1 {
                    _( $args->{title} );
                };

                outs (Jifty->web->page_navigation->render_as_menu);
                }
        };

        show('salutation');

        with( class => "clear" ),   hr  {};
        with( id    => 'content' ), div {
            Jifty->web->render_messages;
            my $buf = '';
            {
            local $Template::Declare::Tags::BUFFER ='';
            $coderef->();
            $buf = $Template::Declare::Tags::BUFFER;
            warn "My buffer is $buf";
            }
            outs($buf);
            with( class => "clear" ), hr { };

            }
        }

};


private template search_box => sub {
    my $action = new_action( class => 'SearchPage' );
    $action->sticky_on_success(1);
    span {
        form {

            form_next_page( url => '/search' );
            param( $action, 'contains', label => 'Search:' );
            }
        };
};

private template salutation => sub {
    with (id => 'salutation'),
        div {

        if (    Jifty->web->current_user->id and Jifty->web->current_user->user_object ) {
            outs('Hiya, ');
            with class => 'user',
                span { Jifty->web->current_user->user_object->name };
            outs('(' . hyperlink( label => q{Logout}, url => '/logout' ) .')');
        } else {
            outs("You're not currently signed in.") .  tangent( label => q{Sign in}, url => '/login' ) . "."; }
        }
};


private template diff => sub {
    my %args = ( page => undef, from => undef, to => undef, @_);

    my $to   =  $args{'to'} ||$args{page}->revisions->last;
    my $from = $args{'from'}|| $to->previous || Wifty::Model::Revision->new;

    my $before = $to->previous;
    my $after  = $to->next;

    use Text::Diff ();
    my $diff = Text::Diff::diff(
        \( $from->content ),
        \( $to->content ),
        { STYLE => 'Text::Diff::HTML' }
    );

    with( class => 'revision_nav' ), div {
        if ($before) {
            span {
                with class => "prev";
                hyperlink(
                    url   => "/view/" . $args{page}->name . "/" . $before->id,
                    label => "Previous revision"
                );
            };
        }
        outs('|') if ( $before and $after );

        if ($after) {
            with( class => "next" ), span {
                hyperlink(
                    url   => "/view/" . $args{'page'}->name . "/" . $after->id,
                    label => "Next revision"
                );
            };
        }
    };
    with class => "diff", pre {
        $diff;
        };
    hr {}

};

template create => sub {
    my ( $action, $page ) = get(qw(action page));
    show(
        'wrapper',
        {title => 'New page: ' . $page, id => 'create' }, 
        sub {p{
            form {
                with( class => 'form_wrapper' ), div {
                    form_next_page( url => '/view/' . $page );
                        param($action => 'name', render_as     => 'hidden', default_value => $page);
                    with( class => 'inline' ), div { param ($action => 'content', rows => 30 ); };
                    with( class => 'line' ), div { form_submit( label => 'Create' );
                    };
                };
            };
            show('markup');
        };
        }
    );
};

template edit => sub {
    my ( $page, $revision, $viewer ) = get(qw(page revision viewer));
    my $can_edit = $page->current_user_can('update');
    show( 'page_nav', page => $page->name, rev => $revision->id );
    show(
        'wrapper',
        {   title => 'Edit: ' . $page->name . ( $revision->id ? " as of " . $revision->created : '' ), id => "update" },
        sub {
            form {
                with( class => 'form_wrapper' ), div {
                    with( class => 'inline' ), div {
                        unless ($can_edit) { with( style => "width: 70%" ), p { q{You don't have permission to edit this page. Perhaps} . tangent( url   => '/login', label => 'logging in') . q{would help. In the mean time, though, you're welcome to view and} . q{copy the source of this page.}; } }
                        form_next_page( url => '/view/' . $page->name );
                        param($viewer => 'content');
                        if ($can_edit) { with( class => 'line' ), div { form_submit( label => 'Save' ); } }
                    };
                };
                show('markup');
                };
            
            }


    );
};

template history => sub {
    my ( $page, $revisions ) = get(qw(page revisions));
    # XXX TODO, this isn't right
    show( 'page_nav', page => $page->name );
    show(
        'wrapper',
        { title => $revisions->count . " revisions of " . $page->name },
        sub {
            with( id => "history" ),

                dl {
                while ( my $rev = $revisions->next ) {
                    dt {
                        hyperlink(
                            label => $rev->created,
                            url   => '/view/' . $page->name . '/' . $rev->id
                        );
                        if ( $rev->created_by->id ) {
                            '(' . $rev->created_by->name . ')';
                        } else {
                            '(Anonymous)';
                        }
                    };
                    dd { length( $rev->content ) . ' bytes' };
                }
                };
        }
    );

};

template login => sub {
    my ( $action, $next, ) = get(qw(action next));
    show(
        'wrapper',
        { title => 'Login' },
        sub {
            if ( not current_user->id ) {
                with( id => 'login-box' ), div {
                    with( call => $next, name => "loginbox" ), form {
                        param($action => 'email');
                        param($action => 'password');
                        param($action => 'remember');
                        form_submit(
                            label  => 'Login',
                            submit => $action
                        );
                    };
                };

                p {
                    tangent(
                        label => q{Don't have an account?},
                        url   => '/signup'
                    );
                };

            } else {
                p {
                    "You're already logged in as "
                        . current_user->user_object->name . "."
                        . "If this isn't you, "
                        . tangent(
                        url   => '/logout',
                        label => 'click here'
                        )
                        . ".";
                    }
            }
        }
    );
};

template logout => sub {
    show(
        'wrapper',
        { title => "Logged out" },
        sub {
            p { _("Ok, you're now logged out. Have a good day.") };
        }
    );
};

template no_such_page => sub {
    my (  $page ) = get(qw(page));
    show(
        'wrapper',
        { title => 'No such page: ' . $page },
        sub {

            p {
                q{Unfortunately, you've tried to reach a page that doesn't exist }
                    . q{yet, and you don't have permissions to create pages. If you }
                    . tangent( url => '/login', label => 'login' )
                    . q{, you'll be able to create new pages of your own.}

                }

        }
    );
};

template pages => sub {
    my ($pages ) = get(qw(pages));
    show(
        'wrapper',
        { title => 'These are the pages on your wiki!' },
        sub {
            show( 'page_list', pages => $pages, id => 'allpages' );
        }
    );

};

template recent => sub {
    my ( $pages ) = get(qw(pages));
    show(
        'wrapper',
        { title => 'Updated this week' },
        sub {
            show( 'page_list', pages => $pages, id => 'recentupdates' );
        }
    );

};

template recent_atom => sub {
    my ( $pages) = get(qw(pages));
    use XML::Atom::SimpleFeed;
    use Data::UUID;
    my $feed = XML::Atom::SimpleFeed->new(
        title   => 'Recently changed pages',
        link    => Jifty->web->url,
        updated => '2009-12-31T00:00:00Z',
        author  => 'John Doe',
        id      => 'urn:uuid:' . Data::UViewD->new->create_str()
    );

    while ( my $page = $pages->next ) {

        $feed->add_entry(
            title   => $page->name,
            link    => Jifty->web->url . '/view/' . $page->name,
            id      => 'urn:uuid:' . Data::UViewD->new->create_str(),
            summary => $page->content,
            updated => $page->updated
        );
    }
    $feed->print;
};

template search => sub {
    my ( $pages, $search ) = get(qw(pages search));
    show( 'wrapper',
        { title => 'Search' },
        sub {
            form {
                with( id    => "searchbox", class => 'inline'), div {
                    param($search => 'contains', label => 'Find pages containing:' );
                    form_submit( label => 'Search', submit => $search);
                    };

            };
            if ($pages) {
                show( 'page_list' => pages => $pages, id => 'searchresults' );
            }
        }
    );
};

template signup => sub {
    my (  $action, $next ) = get(qw(action next));
    show(
        'wrapper',
        { title => 'Signup' },
        sub {
            p {q{Just a few bits of information are all that's needed.}};
            with( call => $next, name => "signupbox" ), form {
                param ($action => 'email');
                param ($action => 'name');
                param ($action => 'password');
                param ($action => 'password_confirm');
                form_submit( label => 'Signup', submit => $action );
            };
        }
    );

};

template view => sub {
    my ( $page, $revision, $viewer ) = get(qw(page revision viewer));
    show( 'page_nav', page => $page->name, rev => $revision->id );
    show(
        'wrapper',
        {   title => $page->name
                . ( $revision->id ? " as of " . $revision->created : '' )
        },
        sub {
            if ( $revision->id ) {
                show( 'diff', page => $page, to => $revision );
            }

            param($viewer => 'content', label => '', render_mode => 'read');
            #$viewer->form_value( 'content', label => "" );

        }
    );

};

private template header => sub {
    my %args = ( title=> undef, wikiname => undef, @_);
    
    my (  $title, $wikiname ) = ($args{'title'}, $args{'wikiname'});
    # $HTML::Mason::r->content_type('text/html; charset=utf-8');
    outs(
        '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
    );

    with(
        xmlns      => "http://www.w3.org/1999/xhtml",
        'xml:lang' => "en"
        ),
        html {
        head {
            with(
                'http-equiv' => "content-type",
                'content'    => "text/html; charset=utf-8"
                ),
                meta {};
            with(
                name    => "robots",
                content => "all"
                ),
                meta {};
            title { _($title) . ' - ' . _($wikiname) };

            Jifty->web->include_css;
            Jifty->web->include_javascript;

            }
        }
};

template markup => sub {
    return undef unless ( Jifty->config->app('Formatter') eq 'Markdown' );

    with( id => 'syntax' ), div {
        div {
            with(
                href    => "#",
                onclick => "Element.toggle('syntax_content');return(false);"
                ),
                a {
                b {'Wiki Syntax Help'};
                }
        };
        with( id => 'syntax_content' ), div {
            h3   {'Phrase Emphasis'};
            code {
                b { '**bold**'; };
                i {'_italic_'};
            };

            h3 {'Links'};

            code {'Show me a [wiki page](WikiPage)'};
            code {'An [example](http://url.com/ "Title")'};

            h3 {'Headers'};

            pre {
                code {
                    join( "\n",
                        '# Header 1',
                        '## Header 2',
                        '###### Header 6' );
                    }
            };

            h3 {'Lists'};

            p {'Ordered, without paragraphs:'};

            pre {
                code {
                    join( "\n", '1.  Foo', '2.  Bar' );
                    }
            };

            p {' Unordered, with paragraphs:'};

            pre {
                code {
                    join( "\n",
                        '*   A list item.',
                        'With multiple paragraphs.',
                        '*   Bar' );
                };

                h3 {'Code Spans'};

                p {
                    code {'`&lt;code&gt;`'}
                        . 'spans are delimited by backticks.';
                };

                h3 {'Preformatted Code Blocks'};

                p {'Indent every line of a code block by at least 4 spaces.'};

                pre {
                    code {
                        'This is a normal paragraph.' . "\n\n" . "\n"
                            . '    This is a preformatted' . "\n"
                            . '    code block.';
                    };
                };

                h3 {'Horizontal Rules'};

                p {
                    'Three or more dashes: ' . code {'---'};
                };

                address {
                    '(Thanks to <a href="http://daringfireball.net/projects/markdown/dingus">Daring Fireball</a>)';
                    }
                }
        };
        script {
            qq{
   // javascript flyout by Eric Wilhelm
   // TODO use images for minimize/maximize button
   // Is there a way to add a callback?
   Element.toggle('syntax_content');
   };
        };
    };
};

package Wifty::View::let;
use Template::Declare::Tags;

# /let/confirm_email

template confirm_email => sub {
    Jifty->api->allow('ConfirmEmail');
    new_action(
        moniker => 'confirm_email',
        class   => 'Wifty::Action::ConfirmEmail'
    )->run;
    redirect("/");
};

1;
