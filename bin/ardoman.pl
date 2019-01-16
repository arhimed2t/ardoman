#!/usr/bin/perl

use strict;
use warnings;

use version; our $VERSION = version->declare("v0.0.1");

use English qw( -no_match_vars );
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
use Readonly;
use Carp qw{ carp confess };
use Cwd qw{};
use File::Spec;

# Calculate path to our libraries
BEGIN {
    my @dirs = File::Spec->splitdir(Cwd::abs_path($PROGRAM_NAME));
    pop @dirs; # Cut executable name
    pop @dirs; # Cut 'bin' dir
    $ENV{'ARDO_WORKDIR'} = File::Spec->catdir(@dirs); ## no critic (Variables::RequireLocalizedPunctuationVars)
    my %inc_hash = map { $_ => 1 } @INC;
    my @inc_dirs = ();
    foreach my $dir_suffix (qw{ lib local/lib }) {
        my $inc_dir = "$ENV{'ARDO_WORKDIR'}/$dir_suffix";
        if (-d $inc_dir && -r _ && !$inc_hash{$inc_dir}) {
            push @inc_dirs, $inc_dir;
        }
    }
    $ENV{'ARDO_DIRS_INC'} = join '::', @inc_dirs;
} # end BEGIN
use lib split /::/smx, $ENV{'ARDO_DIRS_INC'};

use Ardoman::Constants qw{ :all };
use Ardoman::Configuration;
use Ardoman::Docker;

# I limited in size of program, so let Euclid to process arguments logic.
# This module takes POD, parse it and process arguments at start.
# See arguments definitions and descriptions in POD section below.
use Getopt::Euclid qw( :minimal_keys );

use Log::Log4perl;
use Log::Log4perl::Level;
Log::Log4perl->init_once(\$LOG4PERL_DEFAULT);

if ($ARGV{log_conffile}) {
    Log::Log4perl->init($ARGV{log_conffile}); # Note: force reinit logger
}
if ($ARGV{log_level} && Log::Log4perl::Level::is_valid($ARGV{log_level})) {
    my $level = Log::Log4perl::Level::to_priority($ARGV{log_level});
    Log::Log4perl->get_logger($ROOT_LOGGER)->level($level);
}
if ($ARGV{debug}) {
    my $level = Log::Log4perl::Level::to_priority('ALL');
    Log::Log4perl->get_logger($ROOT_LOGGER)->level($level);
}

my $data = {
    endpoint    => {}, # Here we'll save all data about endpoint
    application => {}, # And here about application
};

update_data(endpoint    => $data->{'endpoint'},    \%ARGV);
update_data(application => $data->{'application'}, \%ARGV);

my $conf = Ardoman::Configuration->new($ARGV{'confdir'});
if ($ARGV{'confdir'}) {
    $conf->load(endpoint    => $ARGV{'endpoint'},    $data->{'endpoint'});
    $conf->load(application => $ARGV{'application'}, $data->{'application'});
}

if ($ARGV{'show'}) {
    print Dumper $data;
}

my $result = $EMPTY;
my $api    = Ardoman::Docker->new($data->{'endpoint'});
my $action = $ARGV{'action'};

if ($api && $action && $api->can($action)) {
    $result = $api->$action($data->{'application'});
}

if ($ARGV{'save'}) {
    $conf->save(endpoint    => $ARGV{'endpoint'},    $data->{'endpoint'});
    $conf->save(application => $ARGV{'application'}, $data->{'application'});
}
if ($ARGV{'purge'}) {
    $conf->purge(endpoint    => $ARGV{'endpoint'});
    $conf->purge(application => $ARGV{'application'});
}

print "Done: $result\n";

sub update_data {
    my($type, $target, $source) = @_;

    foreach my $opt_name (@{ $DATA_KEYS->{$type} }) {
        $target->{$opt_name} //= $source->{$opt_name};
    }
}

#__DATA__

__END__


=head1 NAME

ardoman – Arhimed's Docker Manager

=head1 VERSION

This documentation refers to ardoman version 0.0.1.

=head1 USAGE

# Brief working invocation example(s) here showing the most common usage(s)
# This section will be as far as many users ever read,
# so make it as educational and exemplary as possible.

=head1 REQUIRED ARGUMENTS

A complete list of every argument that must appear on the command line.
when the application is invoked, explaining what each of them does, any
restrictions on where each one may appear (i.e., flags that must appear
before or after filenames), and how the various arguments and options
may interact (e.g., mutual exclusions, required combinations, etc.)
If all of the application's arguments are optional, this section
may be omitted entirely.

=head1 OPTIONS

=over

=item --confdir=<confdir>

Directory where is configuration files are located.
Contains two directories 'endpoints' and 'applications' for different types
of configs.
 
=item  --endpoint=<conn>

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

=item --host=<host>

Daemon socket(s) to connect to.
Default to $ENV{DOCKER_HOST}

=item --tls_verify

Use TLS and verify the remote.
Default to $ENV{DOCKER_TLS_VERIFY}

=item --ca_file=<ca_file>

Trust certs signed only by this CA.
Path to ca cert file, default to $ENV{DOCKER_CERT_PATH}/ca.pem

=item --cert_file=<cert_file>

Path to TLS certificate file.
Path to client cert file, default to $ENV{DOCKER_CERT_PATH}/cert.pem

=item --key_file=<key_file>

Path to TLS key file.
Path to client key file, default to $ENV{DOCKER_CERT_PATH}/key.pem

=item --save

Command to save endpoint's and application's configurations into database.

=item --purge

Command to purge both configurations after use (or may be after save also).

=item --show

Command to show configurations before connect to endpoint.

=item --action=<action>

action

=item --ports=<ports>

ports

=item --name=<name>

name

=item --application=<application>

name

=item --image=<image>

name


=back

=head1 DESCRIPTION

A full description of the application and its features.
May include numerous subsections (i.e., =head2, =head3, etc.).

=head1 DIAGNOSTICS

A list of every error and warning message that the application can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies. If the
application generates exit status codes (e.g., under Unix), then list the exit
status associated with each error.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the application,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.
(See also “Configuration Files” in Chapter 19.)





