package Ardoman::Docker::Container;

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.0.3');

use English qw( -no_match_vars );
use Carp;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;

### CLASS METHOD ############################################################
# Usage      : Ardoman::Docker::Container->new( $handler_inst, $id_of_cont );
# Purpose    : Create instance of this class to apply container's commands
# Returns    : Instance
# Parameters : $handler_inst - ready to use handler to API (from parent)
#            : $id_of_cont - Id of container to be modified
# Throws     : Missed $handler_inst
#            : Missed $id_of_cont
# Comments   : none
# See Also   : Ardoman::Docker::Handler, Ardoman::Docker::API
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
# Usage      : $o->Id()
# Purpose    : Get ID of container assosiated with this instance
# Returns    : Id of container as string
# Parameters : none
# Throws     : no exceptions
# Comments   : the name remains exactly the same for compatibility with Eixo
# See Also   : n/a
sub Id { ## no critic (NamingConventions::Capitalization)
    my($self) = @_;

    return $self->{'id'};
}

################################ INTERFACE SUB ##############################
# Usage      : $o->start()
# Purpose    : Start container assosiated with this instance
# Returns    : $self
# Parameters : none
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
sub start {
    my($self) = @_;

    my $query = { id => $self->{'id'} };
    my $data = $self->{'handler'}->request(start => $query);

    return $self;
}

################################ INTERFACE SUB ##############################
# Usage      : $o->stop()
# Purpose    : Stop container assosiated with this instance
# Returns    : $self
# Parameters : none
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
sub stop {
    my($self) = @_;

    my $query = { id => $self->{'id'} };
    my $data = $self->{'handler'}->request(stop => $query);

    return $self;
}

################################ INTERFACE SUB ##############################
# Usage      : $o->delete()
# Purpose    : Delete container assosiated with this instance
# Returns    : $self
# Parameters : none
# Throws     : no exceptions
# Comments   : the name remains exactly the same for compatibility with Eixo
# See Also   : n/a
sub delete { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my($self) = @_;

    my $query = { id => $self->{'id'} };
    my $data = $self->{'handler'}->request(delete => $query);

    return $self;
}

################################ INTERFACE SUB ##############################
# Usage      : $o->top
# Purpose    : Return list of processes run in container assosiated ...
# Returns    : Reference to a hash with 'top' struct in docker format
# Parameters : none
# Throws     : no exceptions
# Comments   : none
# See Also   : docs.docker.com/engine/api/v1.37/#operation/ContainerTop
sub top {
    my($self) = @_;

    my $query = { id => $self->{'id'} };
    my $data = $self->{'handler'}->request(top => $query);

    # Note here returns data
    return $data;
}

1;

__END__

