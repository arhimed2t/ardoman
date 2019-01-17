#!/usr/bin/perl

package Ardoman::Docker;

use strict;
use warnings;

use version; our $VERSION = version->declare("v0.0.1");

use English qw( -no_match_vars );
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
use Readonly;
use List::Util qw{ notall pairgrep };

#
#
use Eixo::Docker::Api;
use Log::Log4perl;

use Ardoman::Constants qw{ :all };

Log::Log4perl->init_once(\$LOG4PERL_DEFAULT);
my $log = Log::Log4perl->get_logger(__PACKAGE__);

sub new {
    my($class, $ep_conf_href) = @_;
    my $self = bless {
        conf => undef,
        api  => undef,
    }, $class;

    if (ref $ep_conf_href ne $HASH) {
        $log->error('Wrong argument for constructor: not hash');
        return;
    }
    if (!$ep_conf_href->{'host'}) {
        $log->warn('Cannot create constructor for API: host absent today');
        return;
    }

    my $api;
    if (!eval { $api = Eixo::Docker::Api->new(%{$ep_conf_href}) }) {
        $log->error(sub { 'Creation API failure:' . Dumper $ep_conf_href });
        return;
    }
    $self->{'api'}  = $api;
    $self->{'conf'} = $ep_conf_href;
    return $self;
} # end sub new

sub deploy {
    my $self     = shift;
    my $app_href = __validate(shift);
    return $ERROR if !$app_href;
    return $ERROR if !$self->{'api'};

    my $id = $self->create($app_href);
    print "ID:" . Dumper $id;
    return $ERROR if !$id;
    $app_href->{'id'} = $id;

    return $ERROR if !$self->start($app_href);
#    return $ERROR if !$self->check($app_href);

    return $id;
} # end sub deploy

sub undeploy {
    my $self     = shift;
    my $app_href = __validate(shift);
    return $ERROR if !$app_href;
    return $ERROR if !$self->{'api'};

    my $id = $self->stop($app_href);
    return $ERROR if !$id;
    $app_href->{'id'} = $id;

    return $ERROR if !$self->delete($app_href);

    # Note: here reverse logic
#    return $ERROR if $self->check($app_href);

    return $id;
} # end sub undeploy

sub create {
    my $self     = shift;
    my $app_href = __validate(shift);
    return $ERROR if !$app_href;
    return $ERROR if !$self->{'api'};

    __special_cases($app_href); # Transform 'Ports', etc.
    print "SCSCSC:" . Dumper $app_href;

    my($cont, $handler, $id);
    $handler = $self->{'api'}->containers;

    print Dumper eval { __crop($app_href) };

    if (!eval { $cont = $handler->create(__crop($app_href)) }) {
        $log->error("Error creating container: $EVAL_ERROR");
        return $ERROR;
    }
    if (!$cont) {
        $log->error("Error creating container: EMPTY RETURNED");
        return $ERROR;
    }
    $id = $cont->Id;

    return $id;
} # end sub create

sub delete {
    my $self     = shift;
    my $app_href = __validate(shift);
    return $ERROR if !$app_href;
    return $ERROR if !$self->{'api'};

    print Dumper $app_href;

    my $cont = $self->_get($app_href);
    if (!$cont) {
        $log->error("Error deleting container: NOT FOUND");
        return $ERROR;
    }
    my $id = $cont->Id;
    if (!eval { $cont->delete(__crop($app_href)) }) {
        $log->error("Error deleting container: $EVAL_ERROR");
        return $ERROR;
    }

    return $id;
} # end sub delete

sub start {
    my $self     = shift;
    my $app_href = __validate(shift);
    return $ERROR if !$app_href;
    return $ERROR if !$self->{'api'};

    my $cont = $self->_get($app_href);
    if (!$cont) {
        $log->error("Error starting container: NOT FOUND");
        return $ERROR;
    }
    my $id = $cont->Id;
    if (!eval { $cont->start(__crop($app_href)) }) {
        $log->error("Error starting container: $EVAL_ERROR");
        return $ERROR;
    }
    return $id;
} # end sub start

sub stop {
    my $self     = shift;
    my $app_href = __validate(shift);
    return $ERROR if !$app_href;
    return $ERROR if !$self->{'api'};

    my $cont = $self->_get($app_href);
    if (!$cont) {
        $log->error("Error stopping container: NOT FOUND");
        return $ERROR;
    }
    my $id = $cont->Id;
    if (!eval { $cont->stop(__crop($app_href)) }) {
        $log->error("Error stopping container: $EVAL_ERROR");
        return $ERROR;
    }

    return $id;
} # end sub stop

sub check {
    my $self     = shift;
    my $app_href = __validate(shift);
    return $ERROR if !$app_href;
    return $ERROR if !$self->{'api'};

    my $cont = $self->_get($app_href);
    if (!$cont) {
        $log->error("Error checking container: NOT FOUND");
        return $ERROR;
    }
    my $id = $cont->Id;
    my @res = ();
    if (!eval { @res = $cont->top(__crop($app_href)) }) {
        $log->error("Error checking container: $EVAL_ERROR");
        return $ERROR;
    }

    my $top_res_href = pop @res;
    if (ref $top_res_href eq $HASH
        && ref $top_res_href->{'Processes'} eq $ARRAY) {
        return $ERROR;
    }

print Dumper \@processes;exit;

    return $id;
} # end sub check

sub _get {
    my($self, $app_href) = @_;
    return $ERROR if !$self->{'api'};
    return $ERROR if caller ne __PACKAGE__;

    my $cont;
    if ($app_href->{'Id'}) {
        $cont = $self->{'api'}->containers->get(id => $app_href->{'Id'});
    }
    elsif ($app_href->{'Name'}) {
        $cont = $self->{'api'}->containers->getByName($app_href->{'Name'});
    }

    return $cont;
} # end sub _get

sub __validate {
    my($arg_href) = @_;
    return $ERROR if caller ne __PACKAGE__;
    return $ERROR if ref $arg_href ne $HASH;

    return __required(__translate($arg_href));
}

Readonly my %TRANSLATE => (
    env   => 'Env',
    cmd   => 'Cmd',
    image => 'Image',
    id    => 'Id',
    name  => 'Name',
    ports => 'Ports', # Be aware: It will be changed in special cases
);

sub __translate {
    my($arg_href) = @_;
    return $ERROR if caller ne __PACKAGE__;
    return $ERROR if ref $arg_href ne $HASH;

    my($app_href, $new_key) = ({}, $EMPTY);
    foreach my $old_key (keys %{$arg_href}) {
        next if !defined $arg_href->{$old_key};
        $new_key = $TRANSLATE{$old_key};
        if ($new_key) {
            $app_href->{$new_key} = $arg_href->{$old_key};
        }
        else {
            $app_href->{$old_key} = $arg_href->{$old_key};
        }
    } # end foreach my $old_key (keys %...)

    return $app_href;
} # end sub __translate

Readonly my %REQUIRED => (
    create => ['Image'],
    delete => ['Name|Id'],
    start  => ['Name|Id'],
    stop   => ['Name|Id'],
    check  => ['Name|Id'],
);

sub __required {
    my($arg_href) = @_;
    return $ERROR if caller ne __PACKAGE__;
    return $ERROR if ref $arg_href ne $HASH;

    my $call_sub = (caller(2))[$CALLER_SUB];
    $call_sub = substr $call_sub, length __PACKAGE__ . '::';

    my $app_keys = join ':', keys %{$arg_href};
    if ($REQUIRED{$call_sub}) {
        my $req_aref = $REQUIRED{$call_sub};
        if (notall { $app_keys =~ /\b ($_) \b/smx } @{$req_aref}) {
            $log->warn("Required argument for command $call_sub missed");
            return $ERROR;
        }
    }

    return $arg_href;
} # end sub __required

Readonly my %ALLOWED => (
    create => [qw{ Image Name Env Cmd Hostname ExposedPorts HostConfig }],
);

sub __crop {
    my($arg_href) = @_;
    return $ERROR if caller ne __PACKAGE__;
    return $ERROR if ref $arg_href ne $HASH;

    my $call_sub = (caller(2))[$CALLER_SUB]; # Note '(eval)', so 2
    $call_sub = substr $call_sub, length __PACKAGE__ . '::';

    my %app_hash = ();
    if ($ALLOWED{$call_sub}) {
        my %allowed_hash = map { $_ => 1 } @{ $ALLOWED{$call_sub} };
        %app_hash = pairgrep { $allowed_hash{$a} } %{$arg_href};
    }

    return %app_hash;
} # end sub __crop

sub __special_cases {
    my($arg_href) = @_;
    return $ERROR if caller ne __PACKAGE__;
    return $ERROR if ref $arg_href ne $HASH;

    # Special cases. OMG
    my(@ports, $cont_port, $host_port, $host_ip);
    if (ref $arg_href->{'Ports'} eq $ARRAY) {
        foreach my $port (@{ $arg_href->{'Ports'} }) {
            @ports = split /:/smx, $port;
            $cont_port = pop @ports // $EMPTY;
            $host_port = pop @ports // $EMPTY;
            $host_ip   = pop @ports // $EMPTY;

            next if !$cont_port;
            $arg_href->{'ExposedPorts'} = { $cont_port => {} };
            $arg_href->{'HostConfig'}->{'PortBindings'} = { $cont_port =>
                [ { 'HostIp' => $host_ip, 'HostPort' => $host_port } ] };
        }
    }

} # end sub __special_cases


