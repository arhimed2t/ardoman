package Ardoman::Docker;

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.0.1');

use English qw( -no_match_vars );
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
use Readonly;
use List::Util qw{ notall none pairgrep };

# Because I limited in total size of application I use
# CPAN module to communicate with Docker API
use Eixo::Docker::Api;
use LWP::UserAgent qw{};

use Carp;
$Carp::Verbose = 1;

Readonly my %TRANSLATE => (
    env   => 'Env',
    cmd   => 'Cmd',
    image => 'Image',
    id    => 'Id',
    name  => 'Name',
    ports => 'Ports', # Be aware: It will be changed in special cases
);

Readonly my %ALLOWED => map { $_ => 1 }
    qw{ Image Name Env Cmd ExposedPorts HostConfig };

### CLASS METHOD ############################################################
# Usage      : Ardoman::Docker->new( \%endpoint_configuration );
# Purpose    : Create instance of this class to deploy/undeploy applications
# Returns    : Instance
# Parameters : \%endpoint_configuration - with required 'host' field
#            :   and optional 'tls_verify' (which turns on SSL connection)
#            :   then therefore need 'ca_file' 'cert_file' 'key_file'
# Throws     : wrong \%endpoint_configuration passed (e.g. not a hash)
#            : missing required 'host' parameter
#            : Eixo::Docker::Api errors (e.g. cannot connect to the endpoint)
# Comments   : none
# See Also   : https://metacpan.org/pod/Eixo::Docker

sub new {
    my($class, $ep_conf) = @_;
    my $self = bless {
        conf => undef,
        api  => undef,
    }, $class;

    if (ref $ep_conf ne 'HASH') {
        croak('Wrong argument for constructor: not hash');
    }
    if (!$ep_conf->{'host'}) {
        croak('Cannot create constructor for API: missing host');
    }

    my $api;
    if (!eval { $api = Eixo::Docker::Api->new(%{$ep_conf}) }) {
        c(sub { 'Creation API failure:' . Dumper $ep_conf });
    }

    $self->{'api'}  = $api;
    $self->{'conf'} = $ep_conf;

    return $self;
} # end sub new

################################ INTERFACE SUB ##############################
# Usage      : $o->deploy( \%application_config )
# Purpose    : Deploy selected application to the endpoint (EP)
#            :   in order 'create', 'start', 'check'
#            :   in last - something run, some processes and HTTP URLs
# Returns    : Id of Docker container which was deployed
# Parameters : \%application_config - with all needed for creation arguments
# Throws     : no exceptions
# Comments   : none
# See Also   : create, undeploy, check
sub deploy {
    my($self, $app_conf) = @_;

    my $id = $self->create($app_conf);
    $app_conf->{'id'} = $id; # for quickness, but not in 'undeploy'

    $self->start($app_conf);
    $self->check($app_conf);

    return $id;
} # end sub deploy

################################ INTERFACE SUB ##############################
# Usage      : $o->undeploy( \%application_config )
# Purpose    : Undeploy application from the EP (stop, rm, test lack of it)
# Returns    : Id of Docker container which was undeployed
# Parameters : ref to hash with one mandatory field either 'name' or 'id'
# Throws     : after remove containers it still reachable
# Comments   : none
# See Also   : deploy
sub undeploy {
    my($self, $app_conf) = @_;

    my $id = $self->stop($app_conf); # Here Id need for output only

    $self->remove($app_conf);

    # Note: here reverse logic
    croak('Application still running') if $self->get($app_conf, 'QUIET');

    return $id;
} # end sub undeploy

################################ INTERFACE SUB ##############################
# Usage      : $o->create( \%application_config )
# Purpose    : Create application container on the EP
# Returns    : Id of Docker container which was created
# Parameters : \%application_config - with all needed for creation parameters
#            :   see POD for detail explanations
# Throws     : Not connected API
#            : Wrong \%application_config - not a hash
#            : Required argument 'image' missing
#            : Eixo::Docker::Api could not create container
#            : Eixo::Docker::Api return wrong container (empty)
# Comments   : none
# See Also   : n/a
sub create {
    my($self, $raw_conf) = @_;

    # We need check it here, in other cases we'll check it in _get
    croak('Not connected API')                if !$self->{'api'};
    croak('Wrong app config: not a hash')     if ref $raw_conf ne 'HASH';
    croak('Required argument missing: image') if !$raw_conf->{'image'};

    my($app_conf, $new_key);
    foreach my $old_key (keys %{$raw_conf}) {
        next if !defined $app_conf->{$old_key};
        $new_key = $TRANSLATE{$old_key};
        $new_conf->{ $new_key || $old_key } = $raw_app_conf->{$old_key};
    }

    # Special case for 'ports'. OMG
    my(@ports, $cont_port, $host_port, $host_ip);
    if (ref $arg_href->{'Ports'} eq 'ARRAY') {
        foreach my $port (@{ $arg_href->{'Ports'} }) {
            @ports = split /:/smx, $port;
            $cont_port = pop @ports // q{};
            $host_port = pop @ports // q{};
            $host_ip   = pop @ports // q{};

            next if !$cont_port;
            $arg_href->{'ExposedPorts'} = { $cont_port => {} };
            $arg_href->{'HostConfig'}->{'PortBindings'} = { $cont_port =>
                    [ { 'HostIp' => $host_ip, 'HostPort' => $host_port } ] };
        } # end foreach my $port (@{ $arg_href...})
    } # end if (ref $arg_href->{'Ports'...})

    my %new_conf = pairgrep { $ALLOWED{$a} } %{$app_conf};

    my($cont, $handler);
    $handler = $self->{'api'}->containers;
    if (!eval { $cont = $handler->create(%new_conf) }) {
        croak("Error creating container: $EVAL_ERROR");
    }
    if (!$cont) {
        croak('Error creating container: empty returned');
    }

    return $cont->Id();
} # end sub create

################################ INTERFACE SUB ##############################
# Usage      : $o->remove( \%application_config )
# Purpose    : Remove previously created container
# Returns    : Id of container
# Parameters : ref to hash with one mandatory field either 'name' or 'id'
# Throws     : Eixo::Docker::Api error
# Comments   : none
# See Also   : n/a
sub remove {
    my($self, $app_conf) = @_;

    my $cont = $self->_get($app_conf);
    if (!eval { $cont->delete() }) {
        croak("Error deleting container: $EVAL_ERROR");
    }

    return $cont->Id();
} # end sub remove

################################ INTERFACE SUB ##############################
# Usage      : $o->undeploy( \%application_config )
# Purpose    : Start previously created container
# Returns    : Id of container
# Parameters : ref to hash with one mandatory field either 'name' or 'id'
# Throws     : Eixo::Docker::Api error
# Comments   : none
# See Also   : n/a
sub start {
    my($self, $app_conf) = @_;

    my $cont = $self->_get($app_conf);
    if (!eval { $cont->start() }) {
        croak("Error starting container: $EVAL_ERROR");
    }
    return $cont->Id();
}

################################ INTERFACE SUB ##############################
# Usage      : $o->undeploy( \%application_config )
# Purpose    : Stop previously started container
# Returns    : Id of container
# Parameters : ref to hash with one mandatory field either 'name' or 'id'
# Throws     : Eixo::Docker::Api error
# Comments   : none
# See Also   : n/a
sub stop {
    my($self, $app_conf) = @_;

    my $cont = $self->_get($app_conf);
    if (!eval { $cont->stop() }) {
        croak("Error stopping container: $EVAL_ERROR");
    }

    return $cont->Id();
} # end sub stop

################################ INTERFACE SUB ##############################
# Usage      : $o->undeploy( \%application_config )
# Purpose    : ????
# Returns    : Id of container
# Parameters : ref to hash with one mandatory field either 'name' or 'id'
#            :   optional $quiet suppres output and dieing (in case undeploy)
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
sub get {
    my($self, $app_conf, $quiet) = @_;

    my $cont = $self->_get($app_conf, $quiet);

    return $cont->Id();
}

################################ INTERFACE SUB ##############################
# Usage      : $o->undeploy( \%application_config )
# Purpose    : Check container to run needed procs and/or response via HTTP
# Returns    : Id of container which successfully passed check
# Parameters : ref to hash with one mandatory field either 'name' or 'id'
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
sub check {
    my($self, @args) = @_;
    my $app_conf = __validate(shift @args);
    return $ERROR if !$app_conf;
    return $ERROR if !$self->{'api'};

    my $cont = $self->_get($app_conf);
    my $id   = $cont->Id;

    # Because services inside should be started before check we wait some
    my $check_delay = $app_conf->{'check_delay'} // $DEFAULT_CHECK_DELAY;
    sleep $check_delay;

    my @raw_top_results = ();
    if (!eval { # Need to suppress build-in output in this function
            no warnings 'redefine'; ## no critic (TestingAndDebugging::ProhibitNoWarnings)
            local *Eixo::Docker::Container::Dumper = sub { return };
            @raw_top_results = $cont->top()
        } ### end eval {...
        ) {
        $log->error("Error checking container: $EVAL_ERROR");
        return $ERROR;
    }

    my $top_results = pop @raw_top_results;
    if (   ref $top_results ne 'HASH'
        || ref $top_results->{'Processes'} ne $ARRAY) {
        $log->error('Wrong format of returned TOP');
        return $ERROR;
    }

    my $processes = $top_results->{'Processes'};
    if (!scalar @{$processes}) {
        $log->error('Empty process list. Nothing run?');
        return $ERROR;
    }

    if (ref $app_conf->{'check_proc'} eq 'ARRAY') {
        foreach my $proc_re (@{ $app_conf->{'check_proc'} }) {
            if (none { $_->[-1] =~ m/$proc_re/smx } @{$processes}) {
                croak("Required process not found: $proc_re");
            }
        }
    }

    if (ref $app_conf->{'check_url'} eq 'ARRAY') {
        my $ua = LWP::UserAgent->new();
        foreach my $url (@{ $app_conf->{'check_url'} }) {
            my $response = $ua->get($url);
            if ($response->is_error()) {
                croak('URL not response: ' . $response->as_string());
            }
        }
    }

    return $id;
} # end sub check

############################################## INTERNAL UTILITY #############
# Usage      : $o->_get( \%application_config [, $quiet_bool ])
# Purpose    : Validate app_conf, search container and return it
# Returns    : Eixo::Docker::Container instanse, (container object)
# Parameters : ref to hash with one mandatory field either 'name' or 'id'
#            :   optional $quiet suppres output and dieing (in case undeploy)
# Throws     : If not connected to API by some resons
#            : Wrong config, e.g. it is not reference to hash
#            : Missing required argument (either of "name" or "id")
#            : Eixo::Docker::API return empty instance
# Comments   : none
# See Also   : n/a
sub _get {
    my($self, $app_conf, $quiet) = @_;

    # Validation section
    croak('Not connected API') if !$self->{'api'};
    croak('Wrong app config: not a hash') if ref $app_conf ne 'HASH';
    if (!$app_conf->{'name'} && !$app_conf->{'id'}) {
        croak('Required argument missing: "name" or "id"');
    }

    my $cont;
    my $handler = $self->{'api'}->containers;
    if ($app_conf->{'id'}) {
        if (!eval { $cont = $handler->get(id => $app_conf->{'id'}) }) {
            croak("Container not found: $app_conf->{'id'}") if !$quiet;
            return; # Otherwise return false to 'get', then 'undeploy'
        }
    }
    elsif ($app_conf->{'name'}) {
        if (!eval { $cont = $handler->getByName($app_conf->{'name'}) }) {
            croak("Container not found: $app_conf->{'name'}") if !$quiet;
            return; # Otherwise return false to 'get', then 'undeploy'
        }
    }

    if (!$cont) {
        croak('Error searching container: empty returned');
    }

    return $cont;
} # end sub _get

1;

__END__

