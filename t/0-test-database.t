#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test the models set up by L<Wifty::Test>

=cut

use Wifty::Test no_plan => 1;

my $admin = Wifty::CurrentUser->superuser;

my $users = Wifty::Model::UserCollection->new(current_user => $admin);
isa_ok($users, 'Wifty::Model::UserCollection');

$users->unlimit;

is($users->count, 2, "Got two users");

my $user = $users->next;

isa_ok($user, 'Wifty::Model::User');
is($user->name, 'Some User', 'name ok');
is($user->email, 'someuser@localhost', 'email ok');
ok($user->password_is('sekrit'), 'password ok');
is($user->email_confirmed, '1');

$user = $users->next;
isa_ok($user, 'Wifty::Model::User');
is($user->name, 'Other User', 'name ok');
is($user->email, 'otheruser@localhost', 'email ok');
ok($user->password_is('motdepasse'), 'password ok');
is($user->email_confirmed, '1');
