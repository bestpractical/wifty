use strict;
use warnings;

package Wifty::View::Page;
use base qw(Jifty::Plugin::ViewDeclarePage::Page);
use Jifty::View::Declare::Helpers;

sub render_page {
    my $self = shift;

    if ( my $logo = Jifty->config->app('Logo') ) {
        div { attr { id is "logo" } 
            img { src is $logo, alt is '' }
        };
    }

    return $self->SUPER::render_page( @_ );
}

sub render_navigation {
    my $self = shift;
    my $wikiname = Jifty->config->app('WikiName') || "Wifty";
    h1 { attr { id is 'wikiname' }
        Jifty->web->link( url => "/", label => _($wikiname) )
    };
    return $self->SUPER::render_navigation( @_ );
}

sub render_title_inhead {
    my $self = shift;
    my $title = shift;
    my $wikiname = Jifty->config->app('WikiName') || "Wifty";
    return $self->SUPER::render_title_inhead( $title .' - '. $wikiname );
}

sub render_title_inpage {
    my $self = shift;
    $self->SUPER::render_title_inpage( @_ );
#    show('/search_box');
    hr { {class is 'clear'} };
    return '';
}

1;
