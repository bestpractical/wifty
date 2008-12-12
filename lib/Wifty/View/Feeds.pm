use warnings;
use strict;

package Wifty::View::Feeds;
use Jifty::View::Declare -base;

use XML::Atom::SimpleFeed;
use Data::UUID;

# XXX: don't know how to redispatch to private template
# right from dispatcher
template 'atom/recent' => sub {
    set(type => 'full');
    show('../atom');
};

template 'atom/recent/diff' => sub {
    set(type => 'diff');
    show('../../atom');
};

template 'atom/recent/headlines' => sub {
    set(type => 'headlines');
    show('../../atom');
};

# XXX: id rendering is not correct
private template 'atom' => sub {
    my ($pages, $type) = get(qw(pages type));
    my $wikiname = Jifty->config->app('WikiName');
    my $title = $wikiname
        ? _('Recently changed pages on %1 wiki', $wikiname)
        : _('Recently changed pages on some wiki');
    my $feed = XML::Atom::SimpleFeed->new(
        title   => $title,
        link    => Jifty->web->url,
        id      => 'urn:uuid:' . Data::UUID->new->create_str()
    );

    while ( my $page = $pages->next ) {
        my $summary = '';
        if ( !$type || $type eq 'full' ) {
            $summary = $page->viewer->form_field('content')->wiki_content;
        }
        elsif ( $type eq 'diff' ) {
            $summary = '<pre>'. $page->revisions->last->diff_from .'</pre>';
        }

        $feed->add_entry(
            id      => 'urn:uuid:' . Data::UUID->new->create_str(),
            link    => Jifty->web->url . '/view/' . $page->name,
            title   => $page->name,
            author  => $page->updated_by->friendly_name,
            updated => $page->updated,
            summary => $summary,
        );
    }
    $feed->print;
};

1;
