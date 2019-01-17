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

use Mocker
# Modules list
qw{
    Log::Log4perl
    Log::Log4perl::Level
    LWP::UserAgent
    FakeResponse
    Eixo::Docker::Api
},
# Mock Log4perl at compile time
[
  'Log::Log4perl',
  [ qw{ init init_once } ],
  get_logger =>  sub {
      return bless {} => 'Log::Log4perl';
  },
  [ qw{ level error debug info warn trace } ] =>
#    sub { print STDERR '-'x 80 . "\n" . Dumper @_; return 1; },
],
[
  'Log::Log4perl::Level',
  [ qw{ to_priority } ] => sub { return 1; },
];

#############################################################################
# Mock some subroutines at run time
MOCK(
  [
    'LWP::UserAgent',
    get => sub { return bless {}, 'FakeResponse' },
  ],
  [
    'FakeResponse',
    is_error => sub { return 0 },
  ],
  [
    'Eixo::Docker::Api',
    new => sub { return bless {}, shift },
    containers => sub { return shift },
    [ qw{ get getByName } ] => sub { return shift },
    [ qw{ create delete start stop } ] =>
        sub { return 1 },
    top => sub { return 1 },
  ],
);

#############################################################################
BEGIN { ok(1, 'Start tests: ' . $PROGRAM_NAME); }

#############################################################################
# Start custom tests here

BEGIN {
  use_ok('Ardoman::Docker', qw{});
}

my $o;

$o = Ardoman::Docker->new();
isnt(ref($o) => 'Ardoman::Docker', 'Instance creation failure. Missing agrs.');

$o = Ardoman::Docker->new({});
isnt(ref($o) => 'Ardoman::Docker', 'Instance creation failure. Empty hash.');

$o = Ardoman::Docker->new({host => 'localhost:2375'});
is(ref($o) => 'Ardoman::Docker', 'Instance creation successful.');

done_testing();

1;

__END__

