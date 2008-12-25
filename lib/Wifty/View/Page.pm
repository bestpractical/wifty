use strict;
use warnings;

package Wifty::View::Page;
use base qw(Jifty::Plugin::ViewDeclarePage::Page);
use Jifty::View::Declare::Helpers;

sub render_page {
    my $self = shift;

    my $wikiname = Jifty->config->app('WikiName') || "Wifty";

    if ( my $logo = Jifty->config->app('Logo') ) {
        div { attr { id is "logo" } 
            img { src is $logo, alt is '' }
        };
    }

    Template::Declare->new_buffer_frame;
    $self->instrument_content;
    my $content = Template::Declare->end_buffer_frame->data;

    div { attr { id is "header" }
        div { attr { id is "wikiheader" }
            $self->render_navigation;
        }
        div { attr { id is "pageheader" }
            h1 { attr { id is "pagename" }; outs( $self->_title ) };
            Jifty->web->page_navigation->render_as_menu;
        }
    };
    $self->render_salutation;
    hr { attr { class is 'clear' } };
    
    Jifty->web->render_messages;

    div { attr { id is "content" };
        outs_raw( $content );
        hr { attr { class is 'clear' } };
    };
    $self->render_jifty_page_detritus;
    return '';
}

sub render_navigation {
    my $self = shift;
    my $wikiname = Jifty->config->app('WikiName') || "Wifty";
    h1 { attr { id is 'wikiname' }
        Jifty->web->link( url => "/", label => _($wikiname) )
    };
    $self->SUPER::render_navigation( @_ );
    show('/search_box');
    return '';
}

=head2 render_title_inhead

Adds " - <wikiname>" after page title.

=cut

sub render_title_inhead {
    my $self = shift;
    my $title = shift;
    my $wikiname = Jifty->config->app('WikiName') || "Wifty";
    return $self->SUPER::render_title_inhead( $title .' - '. $wikiname );
}

sub render_title_inpage { return '' }

sub render_link_inpage {
    my $self = shift;
    my %link = @_;
    if ( ($link{rel}||'') eq 'alternate' && ($link{type}||'') eq 'application/atom+xml' ) {
        my ($type) = $link{'href'} =~ m{/(\w+)$};
        a { attr { href => $link{'href'} };
            img { attr {
                src => '/static/images/feed-icon-14x14.png',
                width => 14, heigth => 14,
                title => $link{'title'}
            } };
            outs(" " . ucfirst $type);
        }
    }
    return '';
}
1;
