use warnings;
use strict;

package Wifty::View;
use Jifty::View::Declare -base;

template 'view' => page {
    my ( $page, $revision, $viewer ) = get(qw(page revision viewer));
    my $rev = $revision->id;
    my $title = $rev
        ? _('%1 as of %2', $page->name, $revision->created)
        : $page->name;
    { title is $title }
    show( 'diff', page => $page, to => $revision ) if $rev;
    render_param($viewer => 'content', label => '', render_mode => 'read');
};

template 'edit' => page {
    my ( $page, $revision, $viewer ) = get(qw(page revision viewer));

    my $title = $revision->id
        ? _('Edit page %1 as of %2', $page->name, $revision->created)
        : _('Edit page %1');
    { title is $title }

    my $can_edit = $page->current_user_can('update');

    show('markup');

    form { div { attr { class is 'form_wrapper' };
        div { attr { class is 'inline' };
            unless ( $can_edit ) {
            }
            form_next_page url => '/view/'.$page->name;
            render_action $viewer, ['content'];
        };
        if ( $can_edit ) {
            div { attr { class is 'line' };
                form_submit label => _('Save')
            }
        }
    } };
};

template create => page {
    my ($action, $page) = get(qw(action page));

    { title is _("New page '%1'", $page), id is 'create' };

    div {
        show('markup');

        form { div { attr { class is 'form_wrapper' };
            form_next_page url => '/view/' . $page;
            render_param $action, 'name',
                render_as => 'hidden',
                default_value => $page;

            render_param $action, 'content', rows => 30;
            form_submit( label => _('Create') );
        } }
    };
};

template no_such_page => page {
    my ($page) = get(qw(page));

    { title is _("No '%1' page", $page) }

    p { 
        q{Unfortunately, you've tried to reach a page that doesn't exist }
        . q{yet, and you don't have permissions to create pages. If you }
        . tangent( url => '/login', label => 'login' )
        . q{, you'll be able to create new pages of your own.}
    }
};

template history => page {
    my ( $page, $revisions ) = get(qw(page revisions));
    { title is $revisions->count . " revisions of " . $page->name }

    dl { { id is 'history' }
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
};

template recent => page {
    my ($pages) = get(qw(pages));
    { title is _('Updated this week') }

    show( 'page_list', pages => $pages, id => 'recentupdates' );
};

template pages => page {
    my ($pages ) = get(qw(pages));
    { title is _('These are the pages on your wiki!') }

    show( 'page_list', pages => $pages, id => 'allpages' );
};

template search => page {
    my ( $pages, $search ) = get(qw(pages search));

    form { div { { id is "searchbox", class is 'inline' }
        render_param $search => 'contains', label => _('Find pages containing:');
        form_submit label => 'Search', submit => $search;
    }; };
    if ( $pages ) {
        show( 'page_list' => pages => $pages, id => 'searchresults' );
    }
};

private template 'search_box' => sub {
    my $action = new_action(class => 'SearchPage', moniker => 'search');
    $action->sticky_on_success(1);
    span { form {
        form_next_page url => '/search';
        render_param $action, 'contains', label => 'Search:';
    } };
};

private template 'menu' => sub {
    my $wikiname = Jifty->config->app('WikiName') || "Wifty";
    h1 { attr { id is 'wikiname' }
        Jifty->web->link( url => "/", label => _($wikiname) )
    }
    div { attr { id => "navigation" };
        Jifty->web->navigation->render_as_menu;
    };
};

private template 'heading_in_wrapper' => sub {
    h1 { attr { class => 'title' }; outs_raw(get('title')) };
    Jifty->web->page_navigation->render_as_menu;
#    show('/search_box');
    hr { {class is 'clear'} }
};


private template markup => sub {
    return undef unless Jifty->config->app('Formatter') eq 'Markdown';

    div {{ id is 'syntax' }
        div {
            a {{
                href    is "#",
                onclick is 'jQuery("syntax_content").toggle();return(false);'
            } b {_('Wiki Syntax Help')} }
        };
        div {{ id is 'syntax_content' }
            h3   {'Phrase Emphasis'};
            code {
                b {'**bold**'; };
                i {'_italic_'};
            };

            h3 {'Links'};

            code {'Show me a [wiki page](WikiPage)'};
            code {'An [example](http://url.com/ "Title")'};

            h3 {'Headers'};

            code { pre { join "\n",
                '# Header 1', '## Header 1', '###### Header 6'
            } };

            h3 {'Lists'};

            p {'Ordered, without paragraphs:'};

            code { pre { join "\n", '1. Foo', '2. Bar' } };

            p {'Unordered, with paragraphs:'};

            code { pre { join "\n",
                '*   A list item.', 
                'With multiple paragraphs.',
                '*   Bar',
            } };

            h3 {'Code Spans'};

            p { code {'`<code>`'}; outs(' - spans are delimited by backticks') };

            h3 {'Preformatted Code Blocks'};

            p {'Indent every line of a code block by at least 4 spaces.'};

            code {
                pre {
                    'This is a normal paragraph.' . "\n\n" . "\n"
                        . '    This is a preformatted' . "\n"
                        . '    code block.';
                };
            };

            h3 {'Horizontal Rules'};

            p {
                outs('Three or more dashes: '); code {'---'};
            };

            address {
                outs_raw '(Thanks to <a href="http://daringfireball.net/projects/markdown/dingus">Daring Fireball</a>)';
            }
        };
        script { outs_raw 'jQuery("syntax_content").toggle();' };
    };
};

private template page_list => sub {
    my ( $pages, $id ) = get(qw(pages id));
    dl {{ id is $id, class is "pagelist" }
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

private template diff => sub {
    my ($page, $from, $to) = get(qw(page from to));

    $to ||= $page->revisions->last;
    $from ||= $to->previous || Wifty::Model::Revision->new;

    my $before = $to->previous;
    my $after  = $to->next;

    use Text::Diff ();
    my $diff = Text::Diff::diff(
        \( $from->content ),
        \( $to->content ),
        { STYLE => 'Text::Diff::HTML' }
    );

    div {{ class is 'revision_nav' }
        if ($before) {
            span {{ class is "prev" }
                hyperlink(
                    url   => "/view/" . $page->name . "/" . $before->id,
                    label => _("Previous revision")
                );
            };
        }
        outs('|') if $before and $after;
        if ($after) {
            span {{ class is "next" }
                hyperlink(
                    url   => "/view/" . $page->name . "/" . $after->id,
                    label => _("Next revision")
                );
            };
        }
    };
    pre {{ class is 'diff' } outs_raw($diff) };
    hr {}
};


1;