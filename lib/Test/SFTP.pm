package Test::SFTP;

use Moose;
use Net::SFTP;
use Test::More;

our $VERSION = '0.01';

# variables for the connection
has 'host'     => ( is => 'rw', isa => 'Str' );
has 'user'     => ( is => 'rw', isa => 'Str' );
has 'password' => ( is => 'rw', isa => 'Str' );

has 'debug' => ( is => 'rw', isa => 'Int', default => 0 );
has 'warn'  => ( is => 'rw', isa => 'Int', default => 0 );

has 'ssh_args' => ( is => 'rw', isa => 'ArrayRef|HashRef' );

# this holds the object itself. that way, users can do:
# $test_sftp->object->get() in a raw manner if they want
has 'object'       => ( is => 'rw' );
has 'connected'    => ( is => 'rw', isa => 'Int', default => 0 );
has 'auto_connect' => ( is => 'rw', isa => 'Int', default => 1 );

#TODO: alarm for eval using "timeout" attribute
sub connect {
    my $self = shift;

    my $eval_return = eval {
        # create the object and store it
        $self->object(
            Net::SFTP->new(
                $self->host,
                'user'     => $self->user,
                'password' => $self->password,
                'debug'    => $self->debug,
                'warn'     => $self->warn,
                'ssh_args' => $self->ssh_args,
            )
        );

        1;
    };

    # make sure the connection flag is set right
    $self->connected( $eval_return ? 1 : 0 );

    return $self->connected;
}

sub can_connect {
    my ( $self, $test ) = @_;
    ok( $self->connect, $test );
    return 0;
}

sub cannot_connect {
    my ( $self, $test ) = @_;
    ok( !$self->connect, $test );
    return 0;
}

sub is_status {
    my ( $self, $status, $test ) = @_;
    my $SPACE = q{ };
    is( ( join $SPACE, ( $self->object->status ) ), $status, $test );
    return 0;
}

sub is_status_number {
    my ( $self, $status, $test ) = @_;
    is( ( $self->object->status )[0], $status, $test );
    return 0;
}

sub is_status_string {
    my ( $self, $status, $test ) = @_;
    is( ( $self->object->status )[1], $status, $test );
    return 0;
}

sub can_get {
    my ( $self, $local, $remote, $test ) = @_;
    my $EMPTY = q{};
    $self->connected || $self->connect;
    if ($test) {
        ok( $self->object->get( $local, $remote ) eq $EMPTY, $test );
    } else {
        $test = $remote;
        ok( $self->object->get($local) eq $EMPTY, $test );
    }
    return 0;
}

sub cannot_get {
    my ( $self, $local, $remote, $test ) = @_;
    $self->connected || $self->connect;
    if ($test) {
        ok( !$self->object->get( $local, $remote ), $test );
    } else {
        $test = $remote;
        ok( !$self->object->get($local), $test );
    }
    return 0;
}

sub can_put {
    my ( $self, $local, $remote, $test ) = @_;
    $self->connected || $self->connect;
    ok( $self->object->put( $local, $remote ), $test );
    return 0;
}

sub cannot_put {
    my ( $self, $local, $remote, $test ) = @_;
    $self->connected || $self->connect;
    ok( !$self->object->put( $local, $remote ), $test );
    return 0;
}

sub can_ls {
    my ( $self, $path, $test ) = @_;
    $self->connected || $self->connect;
    ok( $self->object->ls($path), $test );
    return 0;
}

sub cannot_ls {
    my ( $self, $path, $test ) = @_;
    $self->connected || $self->connect;
    diag( $self->object->ls($path) );
    ok( !$self->object->ls($path), $test );
    return 0;
}

1;

__END__

=head1 NAME

Test::SFTP - An object to help test Net::SFTP

=head1 SYNOPSIS

    use Test::SFTP;

    my $t_sftp = Test::SFTP->new(
        host     => 'localhost',
        user     => 'sawyer',
        password => '2o7U!OYv' # created with genpass, obviously
        ...
    );

    $t_sftp->can_get('file');

    $t_sftp->can_copy('file', 'folder');

=head1 VERSION

This describes Test::SFTP 0.01.

=head1 DESCRIPTION

Unlike most testing frameworks, Test::SFTP provides an object oriented interface. The reason is that it's simply easier to use an object than throw everything as argument each time. Maybe in time, there will be another interface that will accept connection arguments through global package variables.

Test::SFTP uses Net::SFTP for the SFTP functions. This is actually a testing framework for Net::SFTP.

=head1 ATTRIBUTES

Basically there is almost complete corrolation with Net::SFTP attributes, except for a few changes here and there.

=head2 host

The host you're connecting to.

=head2 user

Username you're connecting with.

=head2 password

Password for the username you're connecting with.

=head2 debug

Debugging flag for Net::SFTP. Haven't used it yet, don't know if it will ever come in handy.

=head2 warn

Warning flag for Net::SFTP. Haven't used it yet, don't know if it will ever come in handy.

=head2 ssh_args

SSH arguments, such as used in Net::SFTP. These are actually for Net::SSH::Perl.

=head2 object

This holds the object of Net::SFTP. It's there to allow users more fingergrained access to the object. With that, you can do:

    is( $t_sftp->object->do_read( ... ), 'Specific test not covered in the framework' );

=head2 connected

A boolean attribute to note whether the Net::SFTP object is connected.

Most methods used need the object to be connected. This attribute is used internally to check if it's not connected yet, and if it isn't, it will run the connect method again in order to connect. This behavior can be altered using the following attribute:

=head2 auto_connect

A boolean attribute to note whether we want to connect automatically in case we're running a method that needs a connection but the object isn't marked as connected (refer to the previous attribute).

=head1 SUBROUTINES/METHODS

=head2 connect

Once a Test::SCP object is created, it doesn't connect yet. You should issue:

    $t_sftp->connect

Then you could use the available testing methods described below.

If the auto_connect attribute (which is set by default) is on, it will connect as soon as a testing method is used and it finds out it isn't connected already. 

=head2 can_connect

Checks whether we were able to connect to the machine. It basically runs the connect method, but checks if it was successful.

=head2 cannot_connect

Checks whether we were NOT able to connect to the machine. Runs the connect method adn checks if it unsuccessful.

=head2 is_status

Checks the status of Net::SFTP. It's the same as:
    is( $got, Test::SFTP->object->status, 'testing the status returned by Net::SFTP)

This returns the entire string back. It joins both the error number and the FX2TXT, joined by a space character.

=head2 is_status_number

Returns the status number, the first part of the whole status.

=head2 is_status_string

Many a times, the status that comes from Net::SFTP is actually an array and the error string is the second cell. This method returns the second cell in order to return the actual string of the error.

This returns the FX2TXT part of the status.

=head2 can_get

Checks whether we're able to get a file.

=head2 cannot_get

Checks whether we're unable to get a file.

=head2 can_put

Checks whether we're able to upload a file.

=head2 cannot_put

Checks whether we're unable to upload a file.

=head2 can_ls

Checks whether we're able to ls a folder or file. Can be used to check the existence of files or folders.

=head2 cannot_ls

Checks whether we're unable to ls a folder or file. Can be used to check the existence of files or folders.

=head1 DEPENDENCIES

L<http://search.cpan.org/perldoc?Moose>

L<http://search.cpan.org/perldoc?Net::SFTP>

L<http://search.cpan.org/perldoc?Test::More>

=head1 AUTHOR

Sawyer X, C<< <xsawyerx at cpan.org> >>

=head1 DIAGNOSTICS

You can use the "object" attribute to access the Net::SFTP object directly.

=head1 CONFIGURATION AND ENVIRONMENT

The testing suite for the module itself needs an environment variable called TEST_SFTP_RUN_TEST in order to run. Otherwise it will not run the crucial tests.

There is also another environment variable called TEST_SFTP_SKIP_EXP that helps skip the explanations and gets down to the questions.

=head1 INCOMPATIBILITIES

This module should be incompatible with taint (-T), because it use Net::SFTP that utilizes Net::SSH::Perl that does not pass tainted mode.

=head1 BUGS AND LIMITATIONS

This module will have the same limitations that exist for Net::SFTP. Perhaps more.

Please report any bugs or feature requests to C<bug-test-sftp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-SFTP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::SFTP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-SFTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-SFTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-SFTP>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-SFTP/>

=back


=head1 ACKNOWLEDGEMENTS

Dave Rolsky and David Robins for maintaining Net::SFTP.

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Sawyer X, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

