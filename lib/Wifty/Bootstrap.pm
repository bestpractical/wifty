package Wifty::Bootstrap;

use Wifty::Model::Page;

sub run {
    my $self = shift;

    my $index = Wifty::Model::Page->new();
    $index->create(
        name    => 'HomePage',
        content => 'Welcome to your Wifty'
    );

}

1;
