package Wifty::Model::Revision::Schema;
use Jifty::DBI::Schema;

column page  => 
    refers_to Wifty::Model::Page;

column content =>
    type is 'text',
    render_as 'textarea';

column created => 
    type is 'timestamp';

package Wifty::Model::Revision;
use base qw/Wifty::Record/;
use Jifty::RightsFrom column => 'page';
use DateTime;


sub since { '0.0.5' }


sub create {
    my $self = shift;
    my %args = (@_);

    my $now = DateTime->now();
    $args{'created'} =  $now->ymd." ".$now->hms;
    $self->SUPER::create(%args);

}

1;
