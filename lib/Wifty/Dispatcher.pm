package Wifty::Dispatcher;
use Jifty::Dispatcher -base;

under 'create/*', run {
    set page => $1;
    set action => Jifty->web->new_action( class => 'CreatePage' );
};
1;
