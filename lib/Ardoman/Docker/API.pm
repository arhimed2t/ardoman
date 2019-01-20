package Ardoman::Docker::API;

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.0.3');

use English qw( -no_match_vars );
use Carp;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;

use Ardoman::Docker::Handler;
use Ardoman::Docker::Container;

### CLASS METHOD ############################################################
# Usage      : Ardoman::Docker::API->new( \%endpoint_configuration );
# Purpose    : Create instance of this class, and ability of EP
# Returns    : Instance
# Parameters : Accepts and passes unchanged args to Ardoman::Docker::Handler
# Throws     : no exceptions
# Comments   : none
# See Also   : Ardoman::Docker::Handler, Ardoman::Docker::Container
sub new {
    my($class, @args) = @_;

    my $self = bless {
        handler     => Ardoman::Docker::Handler->new(@args),
        API_version => undef,
    }, $class;

    # Just for checking ability API (& compatibility with Eixo::Docker::Api)
    $self->{'API_version'} = $self->version();

    return $self;
} # end sub new

sub containers { return shift }

################################ INTERFACE SUB ##############################
# Usage      : $o->version
# Purpose    : Get version of API on the endpoint
# Returns    : ApiVersion (in string form)
# Parameters : none
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
sub version {
    my($self) = @_;

    my $data = $self->{'handler'}->request('version');

    return $data->{'ApiVersion'};
}

################################ INTERFACE SUB ##############################
# Usage      : $o->get(id => $id)
# Purpose    : Get container specified by Id
# Returns    : Ardoman::Docker::Container instance
# Parameters : Named arg $id with Id of container to be found
# Throws     : Missing required argument $id
# Comments   : none
# See Also   : getByName
sub get {
    my($self, %args) = @_;

    croak('Missing required argument id for get') if !$args{'id'};

    my $query = {
        all     => 'true',
        filters => { id => [ $args{'id'} ], },
    };

    my $data = $self->{'handler'}->request(select => $query);
    my $id = $data->{'Id'};

    my $cont = Ardoman::Docker::Container->new($self->{'handler'}, $id);

    return $cont;
} # end sub get

################################ INTERFACE SUB ##############################
# Usage      : $o->getByName($name)
# Purpose    : Get container specified by Name
# Returns    : Ardoman::Docker::Container instance
# Parameters : Name of container to be found (unnamed, as string )
# Throws     : Missing required parameter
# Comments   : the name remains exactly the same for compatibility with Eixo
# See Also   : get
sub getByName { ## no critic (NamingConventions::Capitalization)
    my($self, $name) = @_;

    croak('Missing required argument name for getByName') if !$name;

    my $query = {
        all     => 'true',
        filters => { name => [$name], },
    };

    my $data = $self->{'handler'}->request(select => $query);
    my $id = $data->{'Id'};

    my $cont = Ardoman::Docker::Container->new($self->{'handler'}, $id);

    return $cont;
} # end sub getByName

################################ INTERFACE SUB ##############################
# Usage      : $o->create( %creaiton_arguments )
# Purpose    : Create container on the EP with given parameters
# Returns    : Ardoman::Docker::Container instance
# Parameters : Set of paired parameters that are identical to EP query fields
# Throws     : Missing required argument Image
# Comments   : none
# See Also   : n/a
sub create {
    my($self, %args) = @_;

    croak('Missing required argument Image for create') if !$args{'Image'};

    my $query = {};
    if ($args{'Name'}) {
        $query->{'name'} = delete $args{'Name'};
    }

    my $data = $self->{'handler'}->request(create => $query, \%args);
    my $id = $data->{'Id'};

    my $cont = Ardoman::Docker::Container->new($self->{'handler'}, $id);

    return $cont;
} # end sub create

1;

__END__

