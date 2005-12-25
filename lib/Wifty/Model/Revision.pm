package Wifty::Model::Revision::Schema;
use Jifty::DBI::Schema;

column page  => refers_to Wifty::Model::Page;

column content => type is 'text', render_as 'textarea';

column created => type is 'timestamp';

column by => refers_to Wifty::Model::User, since '0.0.18';


package Wifty::Model::Revision;
use base qw/Wifty::Record/;
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

=head2 current_user_can RIGHT

We're using L<Jifty::RightsFrom> to pass off ACL decisions to this
update's page.  But we need to make sure that page history entries aren't
editable, except by superusers. So we override C<current_user_can>
to give the arguments a brief massage before handing off to
C<urrent_user_can> (which we inherit).

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
