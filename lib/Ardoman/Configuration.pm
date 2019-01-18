package Ardoman::Configuration;

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.0.1');

use English qw( -no_match_vars );
use Carp;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;

use File::Path qw{ make_path };
use File::Spec;
use File::Slurp qw{ slurp };
use JSON;
use List::Util qw{ none };
use Readonly;

Readonly my @VALID_DIRS => qw{ endpoints applications };

### CLASS METHOD ############################################################
# Usage      : Ardoman::Configuration->new( $config_root_directory );
# Purpose    : Create instance of this class to load/save/purge config
# Returns    : Instance
# Parameters : $config_root_directory - directory where two types of config
#            :   will be saved ('endpoints' and 'applications')
# Throws     : couldnt create directories or they arent writable
# Comments   : none
# See Also   : https://metacpan.org/pod/Eixo::Docker
sub new {
    my($class, $root_conf_dir) = @_;
    my $self = bless { dir => undef }, $class;

    if ($root_conf_dir) {
        $self->{'dir'} = $root_conf_dir;

        foreach my $type (@VALID_DIRS) {
            my $conf_dir = File::Spec->catdir($root_conf_dir, $type);
            if (!-d $conf_dir) {
                make_path($conf_dir); # Make it recursively
            }
            if (!-d $conf_dir || !-w _) {
                $self->{'dir'} = undef; # Disabe functionality
                croak("Cannot work with confdir: $conf_dir");
            }
        } # end foreach my $type (@VALID_DIRS)
    } # end if ($root_conf_dir)

    return $self;
} # end sub new

################################ INTERFACE SUB ##############################
# Usage      : $o->load( $type, $name )
# Purpose    : Load and parse configuration of $type from correspondig dir
# Returns    : Ref to hash with parsed from JSON configuration
#            : FALSE in non critical failures:
#            :   Functionality disabled (not specified $config_root_dir)
#            :   Name of the ending config file not specified
#            :   File is empty or read error
# Parameters : $type - one of 'endpoints' or 'applications' (which dir use)
#            : $name - name of configuration of endpoint or application
# Throws     : JSON parsing error
# Comments   : none
# See Also   : n/a
sub load {
    my($self, $type, $name) = @_;
    return if !$self->{'dir'}; # Functionality disabled
    return if !$name;          # Name not specified - skip
    croak("Wrong config type: $type") if none { $type eq $_ } @VALID_DIRS;

    my $path = File::Spec->catfile($self->{'dir'}, $type, "$name.json");

    my $json_opts = { relaxed => 1 };
    my $json_data = {};
    my $json_text = slurp($path, { err_mode => 'quiet' });
    return if !$json_text;     # Maybe read error NOTE here it isnt critical

    if (!eval { $json_data = from_json($json_text, $json_opts) }) {
        croak("Error parsing $type configuration: $EVAL_ERROR");
    }

    return $json_data;
} # end sub load

################################ INTERFACE SUB ##############################
# Usage      : $o->save( $type, $name, $data )
# Purpose    : Encode to JSON and save configuration to correspondig dir/file
# Returns    : nothing
# Parameters : $type - one of 'endpoints' or 'applications' (which dir use)
#            : $name - name of configuration of endpoint or application
# Throws     : JSON encoding error
#            : File-oriented operation failure (open, print, close)
# Comments   : none
# See Also   : n/a
sub save {
    my($self, $type, $name, $data) = @_;
    return if !$self->{'dir'}; # Functionality disabled
    return if !$name;          # Name not specified - skip
    croak("Wrong config type: $type") if none { $type eq $_ } @VALID_DIRS;

    my $json_opts = { pretty => 1 };
    my $json_text = q{};
    if (!eval { $json_text = to_json($data, $json_opts) }) {
        croak("Error encoding $type configuration: $EVAL_ERROR");
    }

    my $path = File::Spec->catfile($self->{'dir'}, $type, "$name.json");

    open my $fh, '>', $path or croak("Error save $type config: $OS_ERROR");
    print {$fh} $json_text or croak("Error saving $type configuration");
    close $fh or croak("Cannot close $type config: $OS_ERROR");

    return;
} # end sub save

################################ INTERFACE SUB ##############################
# Usage      : $o->purge( $type, $name, $data )
# Purpose    : Erase saved configuration of endpoint or application
# Returns    : nothing
# Parameters : $type - one of 'endpoints' or 'applications' (which dir use)
#            : $name - name of configuration of endpoint or application
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
sub purge {
    my($self, $type, $name) = @_;
    return if !$self->{'dir'}; # Functionality disabled
    return if !$name;          # Name not specified - skip
    croak("Wrong config type: $type") if none { $type eq $_ } @VALID_DIRS;

    my $path = File::Spec->catfile($self->{'dir'}, $type, "$name.json");
    unlink $path;

    return;
} # end sub purge

1;

__END__


