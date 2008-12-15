use warnings;
use strict;

package Wifty::View::Feeds;
use Jifty::View::Declare -base;

use XML::Atom::SimpleFeed;
use Data::UUID;

private template 'pages_links' => sub {
    my ($title, $path) = get(qw(title path));

    add rel "alternate",
        type => "application/atom+xml",
        title => $title .' '. _('(headlines)'),
        href => "/feeds/atom/$path/headlines",
    ;
    add rel "alternate",
        type => "application/atom+xml",
        title => $title .' '. _('(full content)'),
        href => "/feeds/atom/$path/full",
    ;
    add rel "alternate",
        type => "application/atom+xml",
        title => $title .' '. _('(diffs)'),
        href => "/feeds/atom/$path/diffs",
    ;
};

# XXX: id rendering is not correct
# XXX: don't know how to dispatch to private template
template 'atom/pages' => sub {
    my ($pages, $title, $show_as) = get(qw(pages title show_as));
    $show_as ||= 'headlines';
    my $feed = XML::Atom::SimpleFeed->new(
        title   => $title,
        link    => Jifty->web->url,
        id      => 'urn:uuid:' . Data::UUID->new->create_str()
    );

    while ( my $page = $pages->next ) {
        my $summary = '';
        if ( $show_as eq 'full' ) {
            $summary = $page->viewer->form_field('content')->wiki_content;
        }
        elsif ( $show_as eq 'diff' ) {
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
