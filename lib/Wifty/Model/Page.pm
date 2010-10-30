
package Wifty::Model::Page;
use warnings;
use strict;

use base qw/Wifty::Record/;
use Jifty::DBI::Schema;
use Wifty::Model::User;
use Wifty::Model::RevisionCollection;

use Jifty::Record schema {

column name => 
    type is 'text',
    label is 'Page name',
    is mandatory,
    is distinct;

column content =>
    type is 'text',
    label is 'Content',
    render_as 'Wifty::Form::Field::WikiPage';

column updated =>
    type is 'timestamp',
    label is 'Last updated',
    since '0.0.6';

column updated_by =>
    refers_to Wifty::Model::User,
    since '0.0.16';

column created =>
    type is 'timestamp',
    since '0.0.21';

column created_by =>
    refers_to Wifty::Model::User,
    since '0.0.21';

column revisions =>
    refers_to Wifty::Model::RevisionCollection by 'page';
};

sub create {
    my $self = shift;
    my %args = (@_);
    my $now  = DateTime->now();
    $args{'created'} = $args{'updated'} = $now->ymd . " " . $now->hms;
    $args{'created_by'} = $args{'updated_by'}
        = $self->current_user? $self->current_user->user_object : undef;
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
        page			=> $self->id,
        content			=> $args{'content'},
        created_by      => $args{'updated_by'}
    );

}

sub set_content {
    my $self    = shift;
    my $content = shift;
    my ( $val, $msg ) = $self->_set(column => 'content', value => $content);

    if ($val) {
        $self->_add_revision( content => $content,
                        updated_by =>( $self->current_user? $self->current_user->user_object : undef )
                    );
    }
    return ( $val, $msg );
}

sub viewer {
    my $self = shift;
    return Jifty->web->new_action( class => 'UpdatePage', record => $self );
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
        value  => (   $self->current_user->user_object 
		    ? $self->current_user->user_object->id 
		    : undef )
    );

    return ( $val, $msg );
}

sub revision {
    my $self = shift;
    my $rev = shift;
    return undef unless $self->id;
    return undef unless $rev;

    my $res = new Wifty::Model::Revision;
    $res->load_by_cols( page => $self->id, id => $rev );
    return undef unless $res->id;
    return $res;
}


=head2 current_user_can ACTION

Let everybody read pages. If RequireAuth is set in the app config,
only allow logged-in users to create and edit pages. Otherwise, allow
anyone.

=cut

sub current_user_can {
    my $self = shift;
    my $type = shift;

    if ($type eq 'create' || $type eq 'update') {
        if ( Jifty->config->app('ReadOnly') ) {
            my $cu = $self->current_user;
            return wantarray? (0, 'read_only'): 0 if
                !$cu->is_superuser
                && !($cu->id && $cu->user_object->admin);
        }

        return wantarray? (0, 'require_auth'): 0 if
         Jifty->config->app('RequireAuth')
           && !$self->current_user->is_superuser
           && !$self->current_user->id;

        if ( my $ip = $ENV{'REMOTE_HOST'} ) {
            my $block = Jifty->app_class('Model::BlackList')->load_by_cols(
                type => 'IP', value => $ip
            );
            return wantarray? (0, 'black_ip'): 0 if $block && $block->id;
        }
        return 1;
    } elsif($type eq 'read') {
        return 1;
    }

    return $self->SUPER::current_user_can($type, @_);
}

1;
