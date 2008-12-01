use strict;
use warnings;

package Wifty::View::Page;
use base qw(Jifty::View::Declare::Page);
use Jifty::View::Declare::Helpers;

sub render_body {
    my ($self, $body_code) = @_;

    my $logo = Jifty->config->app('Logo');
    return $self->SUPER::render_body( $body_code ) unless $logo;

    return $self->SUPER::render_body( sub {
        div { attr { id is "logo" } img { src is $logo, alt is '' } };
        $body_code->();
    });
}

1;

