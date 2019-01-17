#!/usr/bin/perl

#############################################################################
# Package HEADER1 (name, version and common for all, except the name)

package Mocker;
# This module checked via percritic on BRUTAL TODO perltidy perlpod

use strict;
use warnings;
use version; our $VERSION = qv('0.0.2');
use English qw{ -no_match_vars };

#############################################################################
# Package HEADER2 (list of exported words)

#use base qw{ Exporter };
#our @EXPORT = qw{ rjf }; ## no critic (Modules::ProhibitAutomaticExportation)
#our @EXPORT_OK   = ();
#our %EXPORT_TAGS = ();

#############################################################################
# Package HEADER3 (standart modules to be included)

use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
use Scalar::Util qw{ blessed reftype };
use PerlIO 'scalar';
use Readonly;

#############################################################################
# Package HEADER4 (our own modules to be included)

#############################################################################
# Package HEADER5 (constants and class variables)

Readonly my $TEST_EMPTY => q{};
Readonly my $TEST_OK    => 1;
Readonly my $TEST_ERROR => $TEST_EMPTY;
Readonly my $TEST_FIRST => 0;
Readonly my $TEST_LAST  => -1;
Readonly my $TEST_ARRAY => 'ARRAY';
Readonly my $TEST_HASH  => 'HASH';
Readonly my $TEST_CODE  => 'CODE';

# CODE PART
#############################################################################

#############################################################################
# PUBLIC SUBROUTINES/METHODS
#############################################################################

sub new {
  my ($class) = @_;
  return bless {}, $class;
}

#############################################################################
# Replaces original instance to mocked
sub import {
  my ($import_pkg, @params) = @_;

  # Save words that means module's names that will be mocked (plain words)
  my @simple_words = grep { not ref } @params;
  #my %modules_hash = map { s/\s+//gsmx; $_ => 1 } @simple_words;
  my %modules_hash;
  foreach my $word (@simple_words) {
    $word =~ s/\s+//gsmx;
    $modules_hash{$word}++;
  }
  if (%modules_hash) {
    # Insert @INC hook to load all module that will be mocked
    unshift @INC, sub {
      my ($self, $package) = @_;
      $package =~ s{/}{::}gsmx;
      $package =~ s{[.]pm}{}smx;
      return if not $modules_hash{$package};
      my $text = qq{package $package;1;};
      if (open my $fh, '<:scalar', \$text) {
        return $fh;
      }
      return;
    };
  }

  # Extract definition to mock subs at compile time
  my @subnames_arefs_list = grep { $TEST_ARRAY eq ref } @params;
  if (scalar @subnames_arefs_list) {
    # Something need to mock now (while BEGIN runs)
    MOCK(@subnames_arefs_list);
  }

  # Save caller package to export `MOCK` procedure
  my $caller_pkg = caller;
  # Disable warnings about redefine and ensure work sub names substtution
  no warnings qw{ redefine }; ## no critic (TestingAndDebugging::ProhibitNoWarnings)
  no strict qw{ refs };       ## no critic (TestingAndDebugging::ProhibitNoStrict)
  *{$caller_pkg . '::MOCK'} = \&MOCK;

  return $TEST_OK;
}

#############################################################################
# Mock many subroutines at one time
# Works with array references only (if not aref - skip it)
sub MOCK {
  my (@mocks_arefs_list) = @_;

  my $self;
  if (defined reftype($mocks_arefs_list[$TEST_FIRST])
      and $TEST_HASH eq reftype($mocks_arefs_list[$TEST_FIRST])
      and defined blessed($mocks_arefs_list[$TEST_FIRST])
      and __PACKAGE__ eq blessed($mocks_arefs_list[$TEST_FIRST])) {
    $self = shift @mocks_arefs_list;
  }

  foreach my $mock_aref (@mocks_arefs_list) {
    if ($mock_aref and $TEST_ARRAY eq ref $mock_aref) {
      mock_sub(@{ $mock_aref });
    }
  }
  return $TEST_OK;
}

#############################################################################
sub mock_sub {
  my (@params) = @_;

  my $self;
  if (defined reftype($params[$TEST_FIRST])
      and $TEST_HASH eq reftype($params[$TEST_FIRST])
      and defined blessed($params[$TEST_FIRST])
      and __PACKAGE__ eq blessed($params[$TEST_FIRST])) {
    $self = shift @params;
  }

  return $TEST_OK if not scalar @params;

  # Extract target module name and validate it
  my ($module) = shift @params;
  if (not defined $module or $TEST_EMPTY eq $module or ref $module) {
    require Carp;
    Carp::croak 'Wrong module name';
  }

  return __mock_sub($module, @params);
}

#############################################################################

sub __mock_sub {
  my ($module, @params) = @_;
  return if __PACKAGE__ ne caller;

  my $default_anon_sub = sub { return 1; };
  my ($subname, @subnames_list, $anon_sub);

  while (scalar @params) {
    $subname = shift @params;
    # Validate subname, save if it's scalar, deref if it's reference to array
    if (defined $subname and $TEST_EMPTY ne $subname and not ref $subname) {
      @subnames_list = $subname;
    }
    elsif (defined $subname and $TEST_ARRAY eq ref $subname) {
      @subnames_list = @{ $subname };
    }
    next if not scalar @subnames_list;

    # Check if next is custom procedure (mock-up), if not - use default
    if (scalar @params
        and $params[$TEST_FIRST]
        and $TEST_CODE eq ref $params[$TEST_FIRST]) {
      $anon_sub = shift @params;
    }
    else {
      $anon_sub = $default_anon_sub;
    }

    # Mock subroutines
    foreach my $name (@subnames_list) {

      # Disable warnings about redefine and ensure work sub names substtution
      no warnings qw{ redefine };  ## no critic (TestingAndDebugging::ProhibitNoWarnings)
      no strict qw{ refs };        ## no critic (TestingAndDebugging::ProhibitNoStrict)

      *{$module . "::$name"} = $anon_sub;
    }
  }
  return $TEST_OK;
}

1;

__END__

=pod

Can be used to replace blessed instance with external subroutine calls to mocked one.

=cut


