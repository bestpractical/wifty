use warnings;
use strict;

=head1 NAME

Wifty::Action::Signup

=cut

package Wifty::Action::Signup;
use Wifty::Action::CreateUser;
use base qw/Wifty::Action::CreateUser/;


use Wifty::Model::User;

=head2 arguments


The fields for C<Signup> are:

=over 4

=item email: the email address

=item password and password_confirm: the requested password

=item name: your full name

=back

=cut

sub arguments {
    my $self = shift;
    my $args = $self->SUPER::arguments;

    my %fields = ( 
        email                        => 1,
        likes_ticky_boxes            => 1,
        name                         => 1,
        never_email                  => 1,
        notification_email_frequency => 1,
        password                     => 1,
        password_confirm             => 1,
    );

    for ( keys %$args ) { delete $args->{$_} unless ( $fields{$_} ); }
    $args->{'email'}{'ajax_validates'} = 1;
    $args->{'password_confirm'}{'label'} = "Type that again?";
    return $args;
}


=head2 validate_email

Make sure their email address looks sane

=cut

sub validate_email {
    my $self  = shift;
    my $email = shift;

    unless ( $email =~ /\S\@\S/ ) {
        return $self->validation_error(email => "That doesn't look like an email address." );
    }

    my $u = Wifty::Model::User->new(current_user => Wifty::CurrentUser->superuser);
    $u->load_by_cols( email => $email );
    if ($u->id) {
      return $self->validation_error(email => 'It looks like you already have an account. Perhaps you want to <a href="/welcome/">sign in</a> instead?');
    }

    return $self->validation_ok('email');
}



=head2 take_action

Overrides the virtual C<take_action> method on L<Jifty::Action> to call
the appropriate C<Jifty::Record>'s C<create> method when the action is
run, thus creating a new object in the database.

Makes sure that the user only specifies things we want them to.

=cut

sub take_action {
    my $self   = shift;
    my $record = Wifty::Model::User->new(current_user => Wifty::CurrentUser->superuser);

    my %values;
    $values{$_} = $self->argument_value($_)
      for grep { defined $self->record->column($_) and defined $self->argument_value($_) } $self->argument_names;
    
    my ($id) = $record->create(%values);
    # Handle errors?
    unless ( $record->id ) {
        $self->result->error("Something bad happened and we couldn't create your account.  Try again later");
        return;
    }

    $self->result->message( "Welcome to Wifty, " . $record->name .".");


    return 1;
}

1;
