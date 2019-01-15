#!/usr/bin/perl

package Ardoman::Constants;

use strict;
use warnings;

use version; our $VERSION = version->declare("v0.0.1");

use English qw( -no_match_vars );
use Data::Dumper;
use Readonly;
use Carp qw{ carp confess };
use Cwd qw{};
use File::Spec;

# Calculate path to our libraries
BEGIN {
    my @dirs = File::Spec->splitdir(Cwd::abs_path($PROGRAM_NAME));
    pop @dirs; # Cut executable name
    pop @dirs; # Cut 'lib' dir
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

use base qw{ Exporter };
our @EXPORT      = ();
our @EXPORT_OK   = ();
our %EXPORT_TAGS = ();

$EXPORT_TAGS{'data'} = [qw{ $DATA_KEYS }];
Readonly our $DATA_KEYS => {
    endpoint    => [qw{ username password email serveraddress }],
    application => [qw{ image name ports command }],
};

$EXPORT_TAGS{'symbols'} = [qw{ $EMPTY }];
Readonly our $EMPTY => q{};

$EXPORT_TAGS{'boolean'} = [qw{ $OK $ERROR $ON $OFF $YES $NO $TRUE $FALSE }];
Readonly our $OK    => 1;
Readonly our $ERROR => $EMPTY;
Readonly our $ON    => 1;
Readonly our $OFF   => 0;
Readonly our $YES   => 1;
Readonly our $NO    => 0;
Readonly our $TRUE  => 1;
Readonly our $FALSE => $EMPTY;

$EXPORT_TAGS{'log'} = [qw{ $ROOT_LOGGER $LOG4PERL_DEFAULT }];
Readonly our $ROOT_LOGGER => $EMPTY;
Readonly our $LOG4PERL_DEFAULT => <<'LOG4PERL_DEFAULT';
log4perl.rootLogger             = ALL, Screen
log4perl.appender.Screen        = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr = 1
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %c [%P]:%p %m%n
LOG4PERL_DEFAULT

my(@all_words);
foreach my $tag (keys %EXPORT_TAGS) {
    push @all_words, @{ $EXPORT_TAGS{$tag} };
}

@EXPORT             = ();
@EXPORT_OK          = @all_words;
$EXPORT_TAGS{'all'} = [@all_words];

