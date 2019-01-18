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
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
use Readonly;

#############################################################################
ok(1, 'Start tests: ' . $PROGRAM_NAME);

#############################################################################
# Start custom tests here

my($id, $id1, $id2);

{   local $INPUT_RECORD_SEPARATOR;
    like($id = qx{ bin/ardoman.pl --usage },
        qr/usage/, 'At least it starts...');

    like(
        $id1 = qx{ bin/ardoman.pl \\
        --image='tutum/hello-world' \\
        --name='hello-test-ardoman' \\
        --check_delay=0 \\
        --action=deploy }, qr/\A\w{64}\n\z/, 'tutum/hello-world deployed'
    );

    like(
        $id2 = qx{ bin/ardoman.pl \\
        --name='hello-test-ardoman' \\
        --action=undeploy }, qr/\A\w{64}\n\z/, 'tutum/hello-world undeployed'
    );

    is($id1, $id2, 'Undeploy the same container. Magic')

}

done_testing();

1;

__END__

