#!/usr/bin/env perl

#############################################################################
# Pragmas and versioning
use strict;
use warnings;
use version; our $VERSION = version->declare('v0.0.1');
use English qw( -no_match_vars );

#############################################################################
# Standart, core modules
use Test::More;
use Test::Exception;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
use Readonly;
use Clone qw{ clone };
use List::Util qw { first };

Readonly my $TOP_RES => [
    dummy => {
        Processes => [ 'PID', 'PPID', 'PPPID', 'PPPPID', 'command2check' ],
    },
];

$Data::Dumper::Indent    = 0;
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Pair      = q{=>};
$Data::Dumper::Sortkeys  = 1;

#############################################################################
# Include mocker with mocked modules
use Test::VirtualModule qw{
    LWP::UserAgent
    FakeResponse
    Ardoman::Docker::API
    FakeContainer
};

#############################################################################
ok(1, 'Start tests: ' . $PROGRAM_NAME);
use_ok('Ardoman::Docker', qw{});

#############################################################################
# Mock some subroutines at run time
Test::VirtualModule->mock_sub(
    'LWP::UserAgent',
    new => sub { return bless {}, shift },
    get => sub { return bless {}, 'FakeResponse' },
);

Test::VirtualModule->mock_sub(
    'FakeResponse', # Instead HTTP::Response
    is_error => sub { return 0 },
);

Test::VirtualModule->mock_sub(
    'Ardoman::Docker::API',
    new => sub { return bless {}, shift },
    containers => sub { return bless { z => q{} }, 'FakeContainer' },
);

Test::VirtualModule->mock_sub(
    'FakeContainer', # Instead Eixo::Docker::Container
    create    => sub { return shift },
    get       => sub { return shift },
    getByName => sub { return shift },
    delete    => sub { return shift },
    start     => sub { return shift },
    stop      => sub { return shift },

    Id  => sub { return 1 },
    top => sub { return @{ clone($TOP_RES) } },

    #    get => sub { return 1 },
    #    getByName => sub { return 1 },
    #    Id        => sub { return shift->{'c'} },
    #    delete    => sub { return shift->{'c'} },
    #    start     => sub { return shift->{'c'} },
    #    stop      => sub { return shift->{'c'} },
);

#############################################################################
# Start custom tests here

my $o;

throws_ok(
    sub { $o = Ardoman::Docker->new() }, # "Forget" pass arguments
    qr/not hash/,
    'Instance creation fail successfully. Missing agrs.',
);

delete local $ENV{'DOCKER_HOST'};
throws_ok(
    sub { $o = Ardoman::Docker->new({}) }, # "Forget" pass host
    qr/missing host/,
    'Instance creation fail successfully. Missing host.',
);

local $ENV{'DOCKER_HOST'} = 'foo';
lives_ok(sub { $o = Ardoman::Docker->new({}) }, 'Instance created (ENV).');
is(ref $o, 'Ardoman::Docker', 'Instance correct type (ENV).');

delete local $ENV{'DOCKER_HOST'};
lives_ok(sub { $o = Ardoman::Docker->new({ host => 'farfar:65536' }) },
    'Instance created.');
is(ref $o, 'Ardoman::Docker', 'Instance correct type');

throws_ok(
    sub { $o->deploy() }, # "Forget" pass arguments
    qr/not hash/,
    'Deploy fail successfully. Missing agrs.',
);

throws_ok(
    sub { $o->deploy({}) }, # "Forget" pass image
    qr/missing: image/,
    'Deploy fail successfully. Missing Image.',
);

is( $o->deploy({ Image => 'hello', Check_delay => 0 }),
    1,
    'Deploy successfully.'
);

throws_ok(
    sub { $o->create() }, # "Forget" pass arguments
    qr/not hash/,
    'Create fail successfully. Missing agrs.',
);

throws_ok(
    sub { $o->create({}) }, # "Forget" pass image
    qr/missing: image/,
    'Create fail successfully. Missing Image.',
);

is( $o->create({ Image => 'hello' }),
    1,
    'Create successfully.'
);

done_testing();

1;

__END__

