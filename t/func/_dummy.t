#!/usr/bin/env perl

# This module checked via percritic on BRUTAL TODO perltidy

#############################################################################
# Pragmas and versioning
use strict;
use warnings;
use version; our $VERSION = qv('0.0.1');
use English qw( -no_match_vars );

#############################################################################
# Standart, core modules
use Test::More;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
use Readonly;

#############################################################################
# Our own modules (Mocking and Virualization)
# Mock external subroutines


#############################################################################
# Mock some subroutines at run time

#############################################################################
BEGIN { ok(1, 'Start tests: ' . $PROGRAM_NAME); }

#############################################################################
# Start custom tests here

BEGIN {
  #use_ok('module', qw{export list});
}




done_testing();


1;

__END__

