package Ardoman::Docker::Container;

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.0.2');

use English qw( -no_match_vars );
use Carp;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;

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
    my($class, $handler, $id) = @_;

    croak('Wrong handler for constructor of container') if !$handler;
    croak('Wrong id of container in constructor')       if !$id;

    my $self = bless {
        handler => $handler,
        id      => $id,
    }, $class;

    return $self;
} # end sub new

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
sub Id {
    my($self) = @_;

    return $self->{'id'};
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
sub start {
    my($self) = @_;

    my $query = { id => $self->{'id'} };
    my $data = $self->{'handler'}->request(start => $query);

    return $self;
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
sub stop {
    my($self) = @_;

    my $query = { id => $self->{'id'} };
    my $data = $self->{'handler'}->request(stop => $query);

    return $self;
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
sub delete {
    my($self) = @_;

    my $query = { id => $self->{'id'} };
    my $data = $self->{'handler'}->request(delete => $query);

    return $self;
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
sub top {
    my($self) = @_;

    my $query = { id => $self->{'id'} };
    my $data = $self->{'handler'}->request(top => $query);

    # Note here returns data
    return $data;
}

1;

__END__

