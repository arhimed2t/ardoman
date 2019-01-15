#!/usr/bin/perl

package Ardoman::Docker;

use strict;
use warnings;

use version; our $VERSION = version->declare("v0.0.1");

use English qw( -no_match_vars );
use Data::Dumper;
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


