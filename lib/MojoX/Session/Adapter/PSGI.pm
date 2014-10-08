package MojoX::Session::Adapter::PSGI;
use 5.010001;
use Mojo::Base 'Mojolicious::Sessions';
our $VERSION = "0.01";

sub load {
    my ($self, $c) = @_;
    my $session = $c->req->env->{'psgix.session'};
    $session->{flash} = delete $session->{new_flash} if exists $session->{new_flash};
    $c->stash->{'mojo.session'} = $session;
}

sub store {
    my ($self, $c) = @_;
    my $env = $c->req->env;

    # Make sure session was active
    my $stash = $c->stash;
    return unless my $session = $stash->{'mojo.session'};
    return unless keys %$session || $stash->{'mojo.active_session'};

    # Don't reset flash for static files
    my $old = delete $session->{flash};
    $session->{new_flash} = $old if $stash->{'mojo.static'};
    delete $session->{new_flash} unless keys %{$session->{new_flash}};

    ## Generate "expires" value from "expiration" if necessary
    #my $expiration = $session->{expiration} // $self->default_expiration;
    #my $default = delete $session->{expires};
    #$session->{expires} = $default || time + $expiration
    #        if $expiration || $default;

    my $expiration = $session->{expiration} // $self->default_expiration;
    $session->{expires} = time + $expiration
            if not defined $session->{expires} and $expiration;

    my $expires    = $session->{expires};
    my $regenerate = delete $session->{regenerate};
    delete $session->{flash} if exists $session->{flash};

    if (defined($expires) && $expires < time) {
        $env->{'psgix.session.options'}{expire} = 1;
    }
    elsif ($regenerate) {
        $env->{'psgix.session.options'}{change_id} = 1;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

MojoX::Session::Adapter::PSGI - PSGI session adapter for Mojolicious

=head1 SYNOPSIS

    use MojoX::Session::Adapter::PSGI;

    my $sessions = MojoX::Session::Adapter::PSGI->new({
        ...
    });

    $app->sessions($sessions);

=head1 DESCRIPTION

MojoX::Session::Adapter::PSGI is ...

=head1 METHODS

=head2 load

=head2 store

=head1 LICENSE

Copyright (C) yowcow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yowcow E<lt>yowcow@cpan.org<gt>

=cut

