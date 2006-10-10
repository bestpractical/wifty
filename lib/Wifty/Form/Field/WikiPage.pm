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
    my $scrubber = HTML::Scrubber->new();

    $scrubber->default(
        0,
        {   '*'   => 0,
            id    => 1,
            class => 1,
            href  => qr{^(?:(?:\w+$)|http:|ftp:|https:|/)}i,

            # Match http, ftp and relative urls
            face   => 1,
            size   => 1,
            target => 1
        }
    );

    $scrubber->deny(qw[*]);
    $scrubber->allow(
        qw[H1 H2 H3 H4 H5 A STRONG EM CODE PRE B U P BR I HR BR SPAN DIV UL OL LI DL DT DD]);
    $scrubber->comment(0);

    $content = Text::Markdown::markdown( $content );
    $content = $scrubber->scrub( $content );
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
