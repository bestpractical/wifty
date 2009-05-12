use strict;
use warnings;

package Wifty::Model::RevisionCollection;
use base qw(Jifty::Collection);

use Scalar::Util qw(blessed);

sub limit_by_page {
    my $self = shift;
    my $page = shift;
    if ( blessed $page ) {
        $page = $page->can('page')? $page->page->id : $page->id;
    }
    return $self->limit(
        @_,
        column         => 'page',
        value          => $page,
        quote_value    => 0,
        case_sensitive => 1
    );
}

sub newer_than {
    my $self = shift;
    my $rev = shift;
    $rev = $rev->id if blessed $rev;

    return $self->limit(
        @_,
        column         => 'id',
        operator       => '>',
        value          => $rev,
        quote_value    => 0,
        case_sensitive => 1
    );
}

sub older_than {
    my $self = shift;
    my $rev = shift;
    $rev = $rev->id if blessed $rev;

    return $self->limit(
        @_,
        column         => 'id',
        operator       => '<',
        value          => $rev,
        quote_value    => 0,
        case_sensitive => 1
    );
}

1;
