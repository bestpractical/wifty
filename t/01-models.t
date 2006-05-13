#!/usr/bin/perl -w
use warnings;
use strict;

=head1 DESCRIPTION

A slightly more complicated test harness for the interactions between
model classes.

=cut


use Jifty::Test tests => 9;

use_ok('Wifty::Model::Page');
use_ok('Wifty::Model::User');
use_ok('Wifty::Model::Revision');

my $system_user = Wifty::CurrentUser->superuser;

my $user = Wifty::Model::User->new(current_user => $system_user);
$user->create(email => 'test@email', name => 'Test User');
ok($user, "Created a user model object");

my $current_user = Wifty::CurrentUser->new(id => $user->id);
ok($current_user, "Created a Wifty::CurrentUser");

my $page = Wifty::Model::Page->new(current_user => $current_user);
$page->create(name => "TestPage", content => "Test Content");
is($page->updated_by->id, $user->id, "Model::Page set updated_by correctly");

$page->set(content => "Second test");

my $revs = Wifty::Model::RevisionCollection->new(current_user => $current_user);
$revs->limit(column => "page", value => $page->id);

is($revs->count, 1, "Model::Page stored a revision");

my $revision = $revs->next;

is($revision->page->id, $page->id, "Revision is of the correct page");
is($revision->created_by->id, $current_user->id, "Revision has the correct creator");
