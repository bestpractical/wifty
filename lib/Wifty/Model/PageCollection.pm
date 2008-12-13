use strict;
use warnings;

package Wifty::Model::PageCollection;
use base qw(Jifty::Collection);

sub recently_created { return (shift)->_recently('created', @_) }
sub recently_updated { return (shift)->_recently('updated', @_) }

sub _recently {
    my $proto = shift;
    my $self = ref($proto)? $proto : new $proto;
    my $column = shift;
    my $time = shift || 7*24*60*60;

    my $then = DateTime->from_epoch( epoch => time - $time );
    $self->limit(
        column   => $column,
        operator => '>',
        value    => $then->ymd,
    );
    $self->order_by( column => $column, order => 'desc' );
    return $self;
}

1;
