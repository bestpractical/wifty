
package Wifty::Model::Revision;
use warnings;
use strict;


use base qw/Wifty::Record/;

use Jifty::DBI::Schema;

use Jifty::Record schema {
    column page =>
        refers_to Wifty::Model::Page
    ;
    column content =>
        type is 'text',
        render_as 'Wifty::Form::Field::WikiPage'
    ;
    column created =>
        type is 'timestamp'
    ;
    column created_by =>
        refers_to Wifty::Model::User,
        since '0.0.20'
    ;
};


use Jifty::RightsFrom column => 'page';
use DateTime;
use Wifty::Model::User;
use Wifty::Model::Page;

sub since { '0.0.5' }

sub create {
    my $self = shift;
    my %args = (@_);

    my $now = DateTime->now();
    $args{'created'} =  $now->ymd." ".$now->hms;
    $self->SUPER::create(%args);

}

sub previous {
    my $self = shift;
    return undef unless $self->id;

    my $revisions = Wifty::Model::RevisionCollection->new;
    $revisions->limit_by_page($self);
    $revisions->older_than($self);
    $revisions->order_by( { column => 'id', order => 'desc' } );
    $revisions->rows_per_page(1);
    return $revisions->first;
}

sub next {
    my $self = shift;
    return undef unless $self->id;

    my $revisions = Wifty::Model::RevisionCollection->new;
    $revisions->limit_by_page($self);
    $revisions->newer_than($self);
    $revisions->order_by( { column => 'id', order => 'asc' } );
    $revisions->rows_per_page(1);
    return $revisions->first;
}

sub diff_from {
    my $to = shift;
    my $from = shift;
    unless ( $from && $from->id ) {
        $from = $to->previous;
    }
    return $to->_diff( $from, $to, @_ );
}

sub diff_to {
    my $from = shift;
    my $to = shift;
    unless ( $to && $to->id ) {
        $to = $from->next;
    }
    return $from->_diff( $from, $to, @_ );
}

sub _diff {
    my $self = shift;
    my ($from, $to, %opt) = @_;
    require Text::Diff;
    return Text::Diff::diff(
        \( $from? $from->content : '' ),
        \( $to ? $to->content : '' ),
        { STYLE => 'Text::Diff::HTML', %opt }
    );
}

sub viewer {
    my $self = shift;
    my $viewer = $self->page->viewer;
    $viewer->argument_value( content => $self->content );
    return $viewer;
}

=head2 current_user_can RIGHT

We're using L<Jifty::RightsFrom> to pass off ACL decisions to this
update's page.  But we need to make sure that page history entries aren't
editable, except by superusers. So we override C<current_user_can>
to give the arguments a brief massage before handing off to
C<current_user_can> (which we inherit).

=cut

sub current_user_can {
    my $self = shift;
    my $right = shift;
    
    if ($right ne 'read' and not $self->current_user->is_superuser) {
        return 0;
    }
    $self->SUPER::current_user_can($right, @_);
}

1;
