use warnings;
use strict;

=head1 NAME

Wifty::Form::Field::WikiPage

=head1 DESCRIPTION

A L<Jifty::Web::Form::Field> subclass that renders itself as a text
field on update, and wikifies itself on read-only display.

=cut

package Wifty::Form::Field::WikiPage;
use base qw(Jifty::Web::Form::Field::Textarea);

use HTML::Scrubber;



=head2 render_value

Render a wikified view of this field's content.

=cut

sub render_value {
    my $self = shift;
    my $field = '<span';
    $field .= qq! class="@{[ $self->classes ]}"> !;
    $field .= $self->wiki_content;
    $field .= qq!</span>\n!;
    Jifty->web->out($field);
    return '';
    
}


=head2 wiki_content

Wikify this field's C<current_value>

=cut


sub wiki_content {
    my $self     = shift;
    my $content  = $self->current_value;

    $content =~ s/(?:\n\r|\r\n|\r)/\n/g;

    if (Jifty->config->app('Formatter') eq 'Markdown' ) {
        require Text::Markdown;
        $content = Text::Markdown::markdown( $content );
    }
    elsif (Jifty->config->app('Formatter') eq 'Kwiki') {
        require Text::KwikiFormatish;
        $content = Text::KwikiFormatish::format( $content );
    }
    return ( $content );
}

=head2 rows

C<WikiPage> forms have 30 rows in their textarea by default

=cut

sub rows { 30 };

=head1 SEE ALSO

L<Text::Markdown>, L<Jifty::Web::Form::Field::Textarea>

=cut

1;
