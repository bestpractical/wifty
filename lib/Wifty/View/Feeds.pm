use warnings;
use strict;

package Wifty::View::Feeds;
use Jifty::View::Declare -base;

use XML::Atom::SimpleFeed;
use Data::UUID;

private template 'pages_links' => sub {
    my ($title, $path) = get(qw(title path));

    ul { attr { class is 'atom-feeds' };
        li { add rel "alternate",
            type => "application/atom+xml",
            title => $title .' '. _('(headlines)'),
            href => "/feeds/atom/$path/headlines",
        }
        li { add rel "alternate",
            type => "application/atom+xml",
            title => $title .' '. _('(full content)'),
            href => "/feeds/atom/$path/full",
        }
        li { add rel "alternate",
            type => "application/atom+xml",
            title => $title .' '. _('(diffs)'),
            href => "/feeds/atom/$path/diffs",
        }
    };
    return '';
};

# XXX: don't know how to dispatch to private template
template 'atom/pages' => sub {
    my ($pages, $title, $show_as) = get(qw(pages title show_as));
    $show_as ||= 'headlines';
    my $feed = XML::Atom::SimpleFeed->new(
        title   => $title,
        link    => Jifty->web->url,
    );

    while ( my $page = $pages->next ) {
        my $last_rev = $page->revisions->last;
        my $summary = '';
        if ( $show_as eq 'full' ) {
            $summary = $page->viewer->form_field('content')->wiki_content;
        }
        elsif ( $show_as eq 'diff' or $show_as eq 'diffs' ) {
            $summary = {
                content => $last_rev->diff_from,
                type => 'xhtml',
            };
        }

        $feed->add_entry(
            title   => $page->name,
            link    => Jifty->web->url . '/view/' . $page->name .'/'. $last_rev->id,
            author  => $page->updated_by->friendly_name,
            updated => $page->updated,
            summary => $summary,
        );
    }
    $feed->print;
};

1;
