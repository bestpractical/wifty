package Wifty::Model::Page::Schema;
use Jifty::DBI::Schema;

column name => 
    type is 'text',
    label is 'Page name',
    is mandatory,
    is distinct;

column content =>
    type is 'text',
    label is 'Content',
    render_as 'textarea';

column updated =>
    type is 'timestamp',
    label is 'Last updated',
    since '0.0.6';

column updated_by =>
    refers_to Wifty::Model::User,
    since '0.0.16';

column revisions =>
    refers_to Wifty::Model::RevisionCollection by 'page';

package Wifty::Model::Page;
use base qw/Wifty::Record/;
use Wifty::Model::RevisionCollection;
use Text::Markdown;
use HTML::Scrubber;


=head2 wiki_content [CONTENT]

Wikify either the content of a scalar passed in as an argument or
this page's "content" attribute.

=cut

sub wiki_content {
    my $self     = shift;
    my $content  = shift || $self->content() || '';
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

sub create {
    my $self = shift;
    my %args = (@_);
    my $now  = DateTime->now();
    $args{'updated'} = $now->ymd . " " . $now->hms;
    $args{'updated_by'} = ( $self->current_user? $self->current_user->user_object : undef );
    my ($id) = $self->SUPER::create(%args);
    if ( $self->id ) {
        $self->_add_revision(%args);
    }
    return ($id);
}

=head2 _add_revision 

Adds a revision for this page. Called by  create and set_content

=over

=item content

=back

=cut

sub _add_revision {
    my $self = shift;
    my %args = (@_);

    my $rev = Wifty::Model::Revision->new( current_user => Wifty::CurrentUser->superuser);
    $rev->create(
        page    => $self->id,
        content => $args{'content'},
        # by      => $args{'updated_by'}
    );

}

sub set_content {
    my $self    = shift;
    my $content = shift;
    my ( $val, $msg ) = $self->SUPER::set_content($content);
    $self->_add_revision( content => $content,
                    updated_by =>( $self->current_user? $self->current_user->user_object : undef )
                );
    return ( $val, $msg );
}

sub _set {
    my $self = shift;
    my ( $val, $msg ) = $self->SUPER::_set(@_);
    my $now = DateTime->now();
    $self->SUPER::_set(
        column => 'updated',
        value  => $now->ymd . " " . $now->hms
    );

    $self->SUPER::_set(
        column => 'updated_by',
        value  => 
                    ( $self->current_user? $self->current_user->user_object : undef )
        
    );

    return ( $val, $msg );
}


=head2 current_user_can ACTION

Let everybody create, read and update pages, but not delete the.

=cut

sub current_user_can {
    my $self = shift;
    my $type = shift;

    # We probably want something like this eventually:
    if ($type =~ /(?:create|read|update)/i) {
        return 1;
    } else {
        return $self->SUPER::current_user_can($type, @_);
    }
}

1;
