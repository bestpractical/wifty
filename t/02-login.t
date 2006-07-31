#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test that we can log in to Wifty

=cut

use constant PER_TRIAL => 3;

use Wifty::Test tests => 5 + PER_TRIAL * 4;
use Jifty::Test::WWW::Mechanize;

my $server = Wifty::Test->make_server;

my $URL = $server->started_ok;

ok($URL, "Started a test server");

my $mech = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok($URL, "Got the homepage");
ok($mech->find_link(text_regex => qr/Sign in/), 'Got the signin link');
$mech->follow_link_ok(text_regex => qr/Sign in/);

sub try_login {
    my $mech = shift;
    my $user = shift;
    my $pass = shift;
    
    {
        local $Test::Builder::Level = $Test::Builder::Level;
        $Test::Builder::Level++;
        $mech->fill_in_action_ok('loginbox', email => $user, password => $pass);
        $mech->submit_html_ok();
    }
}

# Try logging in with a bad user
try_login($mech, 'baduser@localhost', 'notmypassword');
$mech->content_contains('No account has that email address', "Login failed with bad username");

# With a blank password
try_login($mech, 'someuser@localost', '');
$mech->content_contains('need to fill in this field','Login fails with no password');

# With the wrong password
try_login($mech, 'someuser@localhost', 'badmemory');
$mech->content_contains('may have mistyped','Login fails with wrong password');

# Try a correct login
try_login($mech, 'someuser@localhost', 'sekrit');
$mech->content_contains('Welcome back','Logged in');
