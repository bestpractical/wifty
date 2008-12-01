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

private template header => sub {
    my %args = ( title=> undef, wikiname => undef, @_);
    
    my (  $title, $wikiname ) = ($args{'title'}, $args{'wikiname'});
    # $HTML::Mason::r->content_type('text/html; charset=utf-8');
    outs(
        '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
    );

    html {{ xmlns is "http://www.w3.org/1999/xhtml", xml__lang is "en" }
        head {
            meta {{ http_equiv is "content-type", content is "text/html; charset=utf-8" }};
            meta {{ name is 'robots', content is 'all' }};
            title { _($title) . ' - ' . _($wikiname) };

            Jifty->web->include_css;
            Jifty->web->include_javascript;

            }
        }
};

1;
