package Wifty::Model::BlackList;
use warnings;
use strict;

use List::Compare;

use base qw/Wifty::Record/;
use Jifty::DBI::Schema;
use Wifty::Model::User;
use Wifty::Model::RevisionCollection;

use Jifty::Record schema {
    column type =>
        type is 'varchar(32)',
        label is 'value',
        is mandatory,
    ;

    column value =>
        type is 'varchar(255)',
        label is 'value',
        is mandatory,
    ;

    column created =>
        type is 'timestamp',
    ;

    column created_by =>
        refers_to Wifty::Model::User,
    ;
};

sub since { '0.0.23' }

sub create {
    my $self = shift;
    my %args = (@_);
    my $now  = DateTime->now();
    $args{'created'}    ||= $now->ymd . " " . $now->hms;
    $args{'created_by'} ||= $self->current_user? $self->current_user->user_object : undef;
    return $self->SUPER::create(%args);
}

=head2 current_user_can ACTION

=cut

sub current_user_can {
    my $self = shift;
    my $type = shift;

    return 1 if $self->current_user->is_superuser;
    return 0 unless $self->current_user->id;
    return 1 if $self->current_user->user_object->admin;
    return 0;
}

sub update_list {
    my $self = shift;
    my %args = (@_);

    my $current = Jifty->app_class('Model::BlackListCollection')->new;
    $current->limit( column => 'type', value => $args{'type'} );

    my $values = delete $args{'values'} || [];
    unless ( @$values ) {
        while ( my $e = $current->next ) {
            my ($status, $msg) = $e->delete;
            return ($status, $msg) unless $status;
        }
        return (1, "Done");
    }

    my $now  = DateTime->now();
    $args{'created'}    ||= $now->ymd . " " . $now->hms;
    $args{'created_by'} ||= $self->current_user? $self->current_user->user_object : undef;

    my %current = map { $_->value => $_ } @$current;

    my $lc = List::Compare->new(
        '--unsorted', $values, [keys %current]
    );
    foreach my $e ( map $current{$_}, $lc->get_Ronly ) {
        my ($status, $msg) = $e->delete;
        return ($status, $msg) unless $status;
    }
    foreach my $e ( $lc->get_Lonly ) {
        my ($status, $msg) = $self->create( %args, value => $e );
        return ($status, $msg) unless $status;
    }
    return (1, 'Done');
}

1;
