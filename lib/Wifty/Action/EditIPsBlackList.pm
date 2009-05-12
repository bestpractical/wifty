use strict;
use warnings;

=head1 NAME

Wifty::Action::EditIPsBlackList

=cut

package Wifty::Action::EditIPsBlackList;
use base qw/Wifty::Action Jifty::Action/;

use Regexp::Common qw(RE_net_IPv4);
my $re_ip = $RE{net}{IPv4};

use Jifty::Param::Schema;
use Jifty::Action schema {
    param 'ips' =>
        label is 'Block IPs',
        render as 'Textarea',
        default is defer {
            my $list = Jifty->app_class('Model::BlackListCollection')->new;
            $list->limit( column => 'type', value => 'IP' );
            $list->order_by({ column => 'value', order => 'asc' });
            return join "\n", map $_->value, @$list;
        },
    ;
};

sub canonicalize_ips {
    my $self = shift;
    my $ips = shift;

    my @ips;
    my @not_ips;

    foreach my $part ( grep /\S/, split /[^0-9.]+/, $ips ) {
        unless ( $part =~ /^$re_ip$/ ) {
            push @not_ips, $part;
        } else {
            push @ips, $part;
        }
    }
    
    $self->canonicalization_note('ips' => "Some values have been dropped as don't look like IP")
        if @not_ips;

    return \@ips;
}

=head2 take_action

=cut

sub take_action {
    my $self = shift;

    my $ips = $self->argument_value('ips');

    my ($status, $msg) = Jifty->app_class('Model::BlackList')->new->update_list(
        type   => 'IP',
        values => $ips,
    );
    Jifty->log->error("$status $msg");
    return $self->result->error( $msg )
        unless $status;

    return $self->report_success;
}

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    # Your success message here
    $self->result->message('Success');
}

1;

