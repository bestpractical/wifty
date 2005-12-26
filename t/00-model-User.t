#!/usr/bin/perl -w
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the User model.

=cut

use Jifty::Test tests => 12;

# Make sure we can load the model
use_ok('Wifty::Model::User');

# Grab a system use
my $system_user = Wifty::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = Wifty::Model::User->new(current_user => $system_user);
my ($id) = $o->create(email => 'an@email', name => 'name');
ok($id, "User create returned success");
ok($o->id, "New User has valid id set");
is($o->id, $id, "Create returned the right id");

ok($o->auth_token, "We have an auth token! ".$o->auth_token);

# And another
$o->create(email => 'some@mail', name => 'another');
ok($o->id, "User create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  Wifty::Model::UserCollection->new(current_user => $system_user);
$collection->unlimit;
is($collection->count, 2, "Finds two records");

# Searches in specific
$collection->limit(column => 'id', value => $o->id);
is($collection->count, 1, "Finds one record with specific id");

# Delete one of them
$o->delete;
$collection->redo_search;
is($collection->count, 0, "Deleted row is gone");

# And the other one is still there
$collection->unlimit;
is($collection->count, 1, "Still one left");

