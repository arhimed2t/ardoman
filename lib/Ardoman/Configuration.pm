#!/usr/bin/perl

package Ardoman::Configuration;

use strict;
use warnings;

use version; our $VERSION = version->declare("v0.0.1");

use English qw( -no_match_vars );
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
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

use File::Path qw{ make_path };
use File::Slurp qw{ slurp };
use JSON;
use List::Util qw{ none };
use Log::Log4perl;

use Ardoman::Constants qw{ :all };

Log::Log4perl->init_once(\$LOG4PERL_DEFAULT);
my $log = Log::Log4perl->get_logger(__PACKAGE__);

sub new {
    my($class, $conf_dir) = @_;
    my $self = bless { _dir => $conf_dir }, $class;

    $self->_check_dirs();
    return $self;
}

sub _check_dirs {
    my $self = shift;
    if (caller ne __PACKAGE__) {
        $log->logconfess('Private function!');
    }
    my $dir = $self->{'_dir'};

    foreach my $type (keys %{$DATA_KEYS}) {
        my $conf_dir = "$dir/${type}s";
        if (!-d $conf_dir) { make_path($conf_dir); }
        if (!-d $conf_dir || !-w _) {
            $log->error("Cannot work with confdir: $conf_dir");
            return $ERROR;
        }
    }

    return $OK;
} # end sub _check_dirs

sub _validate {
    my($type) = @_;

    if (caller ne __PACKAGE__) {
        $log->logconfess('Private function!');
    }
    if (none { $type eq $_ } keys %{$DATA_KEYS}) {
        $log->logconfess("Wrong type of config: $type");
    }
    return $OK;
} # end sub _validate

sub load {
    my($self, $type, $name, $target) = @_;
    return $OK    if !$self->{'_dir'};      # Functionality disabled
    return $ERROR if !$name;                # Name not specified - skip
    return $ERROR if !$self->_check_dirs(); # Not able to read/write
    return $ERROR if !_validate($type);     # If not valid - die inside

    my $full_path = "$self->{'_dir'}/${type}s/$name.json";
    if (!open my $fh, '<', $full_path) {
        $log->warn("Cannot open $type config: $OS_ERROR");
        return $ERROR;
    }
    else {
        my $json_opts = { relaxed => $YES };
        my $json_data = {};
        my $json_text = slurp($fh, { err_mode => 'quiet' });
        if (!defined $json_text) {
            confess("Cannot read $type config");
            return $ERROR;
        }
        close $fh or carp("Cannot close $type config: $OS_ERROR");

        if (!eval { $json_data = from_json($json_text, $json_opts) }) {
            carp("Error parsing $type configuration: $EVAL_ERROR");
            return $ERROR;
        }
        foreach my $opt_name (@{ $DATA_KEYS->{$type} }) {
            $target->{$opt_name} //= $json_data->{$opt_name};
        }
    } # end else [ if (!open my $fh, '<',...)]

    return $OK;
} # end sub load

sub save {
    my($self, $type, $name, $data) = @_;
    return $OK    if !$self->{'_dir'};      # Functionality disabled
    return $ERROR if !$name;                # Name not specified - skip
    return $ERROR if !$self->_check_dirs(); # Not able to read/write
    return $ERROR if !_validate($type);     # If not valid - die inside

    my $full_path = "$self->{'_dir'}/${type}s/$name.json";
    if (!open my $fh, '>', $full_path) {
        $log->error("Error opening for save $type config: $OS_ERROR");
        return $ERROR;
    }
    else {
        my $json_opts = { pretty => $YES };
        my $json_text = q{};
        if (!eval { $json_text = to_json($data, $json_opts) }) {
            $log->error("Error coding $type configuration: $EVAL_ERROR");
            return $ERROR;
        }
        if (!print $fh $json_text) {
            $log->error("Error saving $type configuration");
        }
        close $fh or carp("Cannot close $type config: $OS_ERROR");
    } # end else [ if (!open my $fh, '>',...)]

    return $OK;
} # end sub save

sub purge {
    my($self, $type, $name) = @_;
    return $OK    if !$self->{'_dir'};      # Functionality disabled
    return $ERROR if !$name;                # Name not specified - skip
    return $ERROR if !$self->_check_dirs(); # Not able to read/write
    return $ERROR if !_validate($type);     # If not valid - die inside

    my $full_path = "$self->{'_dir'}/${type}s/$name.json";
    unlink $full_path;

    return $OK;
} # end sub purge

