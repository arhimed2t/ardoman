#!/usr/bin/perl

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.0.1');

use English qw( -no_match_vars );
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
use Readonly;

use Ardoman::Configuration;
use Ardoman::Docker;

# I limited in size of program, so let Euclid to process arguments logic.
# This module takes POD, parse it and process arguments at start.
# See arguments definitions and descriptions in POD section below.
use Getopt::Euclid qw( :minimal_keys );

Readonly my $DATA_KEYS => {
    endpoint    => [qw{ host tls_verify ca_file cert_file key_file }],
    application => [
        qw{ image name id ports cmd env
            check_proc check_url check_delay }
    ],
};

my $data = {
    endpoint    => {}, # Here we'll save all data about endpoint
    application => {}, # And here about application
};

my $endpoint_name    = $ARGV{'endpoint'};
my $application_name = $ARGV{'application'};

#############################################################################
# Start REAL work

update_data(endpoint    => \%ARGV, $data->{'endpoint'});
update_data(application => \%ARGV, $data->{'application'});

my $conf = Ardoman::Configuration->new($ARGV{'confdir'});

# By default - load
if ($ARGV{'confdir'}) {
    update_data(
        endpoint => $conf->load(endpoint => $endpoint_name),
        $data->{'endpoint'},
    );
    update_data(
        application => $conf->load(application => $application_name}),
        $data->{'application'},
    );
} # end if ($ARGV{'confdir'})

if ($ARGV{'show'}) {
    print 'DATA:' . Dumper($data);
}

if ($ARGV{'save'}) {
    $conf->save(endpoint    => $endpoint_name,    $data->{'endpoint'});
    $conf->save(application => $application_name, $data->{'application'});
}

if ($ARGV{'purge'}) {
    $conf->purge(endpoint    => $endpoint_name);
    $conf->purge(application => $application_name);
}

my $api    = Ardoman::Docker->new($data->{'endpoint'});
my $action = $ARGV{'action'};

if ($api && $action && $api->can($action)) {
    print $api->$action($data->{'application'});
}

exit 0;

#    print "Done: $result\n"; ## no critic (InputOutput::RequireCheckedSyscalls)

sub update_data {
    my($type, $source, $target) = @_;

    return if ref $source ne 'HASH' || ref $target ne 'HASH';

    foreach my $opt_name (@{ $DATA_KEYS->{$type} }) {
        $target->{$opt_name} //= $source->{$opt_name};
    }
    return;
}

__END__


=head1 NAME

ardoman – Arhimed's Docker Manager

=head1 VERSION

This documentation refers to ardoman version 0.0.1.

=head1 USAGE

# Brief working invocation example(s) here showing the most common usage(s)
# This section will be as far as many users ever read,
# so make it as educational and exemplary as possible.



    PERL5LIB=lib:local/lib/perl5 bin/ardoman.pl \
        --confdir config \
        --endpoint localhost \
        --host localhost:2375 \
        --name tomcat \
        --application tomcat \
        --action deploy \
        --image tomcat \
        --check_proc java \
        --ports 8080:8080 \
        --check_delay 3 \
        --check_url http://127.0.0.1:8080/ \
        --save

    PERL5LIB=lib:local/lib/perl5 bin/ardoman.pl \
        --confdir config \
        --endpoint localhost \
        --name tomcat1 \
        --application tomcat \
        --action deploy \
        --ports 8081:8080 \
        --check_delay 3 \
        --check_url http://127.0.0.1:8081/


=head1 OPTIONS

=over

=item --confdir [=] <confdir>

Directory where is configuration files are located.
Contains two directories 'endpoints' and 'applications' for different types
of configs.
 
=item  --endpoint [=] <conn>

Name of connection setting to docker endpoint.
Incorporates such option as:
    host
    tls_verify
    ca_file
    cert_file
    key_file
This also name for operating with saved configuration: save, load, purge.
So it must be uniq, otherwise in save case endpoint options
will be overwritten.

=item --host [=] <host>

Daemon socket(s) to connect to.
Default to $ENV{DOCKER_HOST}

=item --tls_verify

Use TLS and verify the remote.
Default to $ENV{DOCKER_TLS_VERIFY}

=item --ca_file [=] <ca_file>

Trust certs signed only by this CA.
Path to ca cert file, default to $ENV{DOCKER_CERT_PATH}/ca.pem

=item --cert_file [=] <cert_file>

Path to TLS certificate file.
Path to client cert file, default to $ENV{DOCKER_CERT_PATH}/cert.pem

=item --key_file [=] <key_file>

Path to TLS key file.
Path to client key file, default to $ENV{DOCKER_CERT_PATH}/key.pem

=item --save

Command to save endpoint's and application's configurations into database.

=item --purge

Command to purge both configurations after use (or may be after save also).

=item --show

Command to show configurations before connect to endpoint.

=item --action [=] <action>

action

=item --ports [=] <ports>

ports

=for Euclid:
    repeatable

=item --env [=] <env>

ports

=for Euclid:
    repeatable

=item --name [=] <name>

name

=item --id [=] <id>

name

=item --application [=] <application>

name

=item --image [=] <image>

name

=item --cmd [=] <cmd>...

name

=item --check_proc [=] <check_proc>

name

=for Euclid:
    repeatable

=item --check_url [=] <check_url>

name

=for Euclid:
    repeatable


=item --check_delay [=] <check_delay>

=for Euclid:
    check_delay.type: integer

name

=item --debug

name

=item --log_level [=] <log_level>

name

=item --log_conffile [=] <log_conffile>

name

=back

=head1 DESCRIPTION

A full description of the application and its features.
May include numerous subsections (i.e., =head2, =head3, etc.).

=head1 DIAGNOSTICS

The program supports logging with Log::Log4perl. By default, logging is
disabled. You can enable all log messages by setting the argument "--debug".

You can also set a certain level of output messages with the argument
"--log_level".  As a value, you should specify in the form of a string a real
logging level used by Log::Log4perl.

For more flexibility, you can specify the Log::Log4perl settings file with the
"--log_confile" argument.

For run test, use:

    PERL5LIB=t/lib:lib:local/lib/perl5 prove -r -v

=head1 CONFIGURATION AND ENVIRONMENT

Since it was necessary to write quickly and briefly, I chose to save the
configuration in files in the "JSON" format. I also decided that it would be
convenient to separate the configuration of the endpoint and the application.
This allows us to deploy one application to multiple endpoints and vice versa
to deploy different applications to one endpoint.

Therefore, the argument "--confdir" to the program is the directory where the
configuration files will be located.  For applications in the "applications"
folder, for endpoints in the "endpoints" folder. Work with the configuration
is carried out regardless of the action specified by the argument "action".
When specifying the argument to the program "--confdir", an automatic loading
of the saved configurations from the corresponding files occurs. However,
command line agruments of course takes precedence and overwrite data from
configurations. 

When specifying the "--save" argument after connecting the saved configuration
with the command line arguments, the program saves the data in a file.

If the "purge" argument is also specified (or only), configuration files are
deleted at the last stage, before exiting the program.






