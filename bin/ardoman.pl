#!/usr/bin/perl

use strict;
use warnings;

use English qw( -no_match_vars );
use Data::Dumper;
use Readonly;
use Carp qw{ carp confess };
use File::Path qw{ make_path };
use File::Slurp qw{ slurp };
use JSON;

# I limited in size of program, so let Euclid to process arguments logic.
# This module takes POD, parse it and process arguments at start.
# Arguments definitions and descriptions in POD section below.
use Getopt::Euclid qw( :minimal_keys );
print "ARGV:" . Dumper \%ARGV;

Readonly my $YES   => 1;
Readonly my $NO    => 0;
Readonly my $OK    => 1;
Readonly my $ERROR => q{};

Readonly my $DATA_KEYS => {
    endpoint    => [qw{ username password email serveraddress }],
    application => [qw{ image name ports command }],
};

my $data = {
    endpoint    => {}, # Here we'll save all data about endpoint
    application => {}, # And here about application
};

update_data(endpoint    => $data->{'endpoint'},    \%ARGV);
update_data(application => $data->{'application'}, \%ARGV);

if ($ARGV{'confdir'}) {
    configuration(load => $data);
}
if ($ARGV{'confdir'} && $ARGV{'save'}) {
    configuration(save => $data);
}
if ($ARGV{'confdir'} && $ARGV{'purge'}) {
    configuration(purge => $data);
}
print "data:" . Dumper $data;

sub configuration {
    my($action, $data) = @_;
    foreach my $type (keys %{$DATA_KEYS}) {
        my $conf_dir = "$ARGV{'confdir'}/${type}s";
        if (!-d $conf_dir) { make_path($conf_dir); }
        confess('Cannot work with confdir') if !-d $conf_dir || !-w _;

        next if !$ARGV{$type};
        my $fname = "$conf_dir/$ARGV{$type}.json";

        if ($action eq 'load') {
            load_json($type, $data->{$type}, $fname);
        }
        elsif ($action eq 'save') {
            save_json($type, $fname, $data->{$type});
        }
        elsif ($action eq 'purge') {
            unlink $fname or carp("Cannot del files: $OS_ERROR");
        }
    }
    return $OK;
} # end sub read_configuration

sub load_json {
    my($type, $target, $fname) = @_;

    if (open my $fh, '<', $fname) {
        my $json_data = {};
        my $json_opts = { relaxed => $YES };
        my $json_text = slurp($fh, { err_mode => 'carp' });
        close $fh or carp("Cannot close $type config: $OS_ERROR");

        if (!eval { $json_data = from_json($json_text, $json_opts) }) {
            carp("Error parsing $type configuration: $EVAL_ERROR");
            return $ERROR;
        }
        update_data($type, $target, $json_data);
    }
    return $OK;
} # end sub read_json_config

sub save_json {
    my($type, $fname, $data) = @_;

    if (!open my $fh, '>', $fname) {
        carp("Error opening for save $type config: $OS_ERROR");
    }
    else {
        my $json_opts = { pretty => $YES };
        my $json_text = q{};
        if (!eval { $json_text = to_json($data, $json_opts) }) {
            carp("Error coding $type configuration: $EVAL_ERROR");
            return $ERROR;
        }
        print $fh $json_text;
        close $fh or carp("Cannot close $type config: $OS_ERROR");
    }

    return $OK;
} # end sub read_json_config

sub update_data {
    my($type, $target, $source) = @_;

    foreach my $opt_name (@{ $DATA_KEYS->{$type} }) {
        $target->{$opt_name} //= $source->{$opt_name};
    }
}

#__DATA__

__END__


=head1 NAME

<application name> – <One-line description of application's purpose>

=head1 VERSION

The initial template usually just has:

This documentation refers to <application name> version 0.0.1.

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
  username
  password
  email
  serveraddress
This also name for oprating with saved configuration: save, load, delete.
So it must bu uniq, otherwise in save case connected option will overwritten.

=item --username=<username>

Username

=item --password=<password>

Password

=item --email=<email>

email

=item --serveraddress=<serveraddress>

serveraddress

=item --save

save 

=item --purge

purge

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





