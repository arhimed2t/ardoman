package Ardoman::Docker::API;

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.0.2');

use English qw( -no_match_vars );
use Carp;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;

use Ardoman::Docker::Handler;
use Ardoman::Docker::Container;

$Carp::Verbose = 1; ## no critic (Variables::ProhibitPackageVars)

### CLASS METHOD ############################################################
# Usage      : Ardoman::Docker->new( \%endpoint_configuration );
# Purpose    : Create instance of this class
# Returns    : Instance
# Parameters :
#            :
#            :
# Throws     :
#            :
#            :
# Comments   :
# See Also   :
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
# Usage      :
# Purpose    :
#            :
#            :
# Returns    :
# Parameters :
# Throws     :
# Comments   :
# See Also   :
sub version {
    my($self) = @_;

    my $data = $self->{'handler'}->request('version');

    return $data->{'ApiVersion'};
}

################################ INTERFACE SUB ##############################
# Usage      :
# Purpose    :
#            :
#            :
# Returns    :
# Parameters :
# Throws     :
# Comments   :
# See Also   :
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
# Usage      :
# Purpose    :
#            :
#            :
# Returns    :
# Parameters :
# Throws     :
# Comments   :
# See Also   :
sub getByName {
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

