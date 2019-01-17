package Ardoman::Configuration;

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.0.1');

use English qw( -no_match_vars );
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
use Carp;

use File::Path qw{ make_path };
use File::Spec;
use File::Slurp qw{ slurp };
use JSON;
use List::Util qw{ none };
use Readonly;

Readonly my %VALID_DATA => (
    endpoint    => [qw{ host tls_verify ca_file cert_file key_file }],
    application => [
        qw{ image name id ports cmd env
            check_proc check_url check_delay }
    ],
);
Readonly my @VALID_DIRS => map { $_ . 's' } keys %VALID_DATA;

sub new {
    my($class, $root_conf_dir) = @_;
    my $self = bless { dir => undef }, $class;

    if ($root_conf_dir) {
        foreach my $type (@VALID_DIRS) {
            my $conf_dir = File::Spec->catdir($root_conf_dir, $type);
            if (!-d $conf_dir) {
                make_path($conf_dir); # Make it recursively
            }
            if (!-d $conf_dir || !-w _) {
                croak("Cannot work with confdir: $conf_dir");
            }
        }
    }

    if (-d $root_conf_dir && -w _) {
        $self->{'dir'} = $root_conf_dir;
    }

    return $self;
}

sub load {
    my($self, $type, $name, $target) = @_;
    return if !$self->{'dir'}; # Functionality disabled
    return if !$name;          # Name not specified - skip
    croak("Wrong config type: $type") if none { $type eq $_ } @VALID_DIRS;

    my $full_path = File::Spec->catfile($self->{'dir'}, $type, "$name.json");

    my $json_opts = { relaxed => 1 };
    my $json_data = {};
    my $json_text = slurp($full_path, { err_mode => 'quiet' });
    return if !$json_text; # Maybe read error NOTE here it is not critical

    if (!eval { $json_data = from_json($json_text, $json_opts) }) {
        croak("Error parsing $type configuration: $EVAL_ERROR");
    }

    return $json_data;
} # end sub load

sub save {
    my($self, $type, $name, $data) = @_;
    return if !$self->{'dir'}; # Functionality disabled
    return if !$name;          # Name not specified - skip
    croak("Wrong config type: $type") if none { $type eq $_ } @VALID_DIRS;

    my $json_opts = { pretty => 1 };
    my $json_text = q{};
    if (!eval { $json_text = to_json($data, $json_opts) }) {
        croak("Error coding $type configuration: $EVAL_ERROR");
    }

    my $full_path = File::Spec->catfile($self->{'dir'}, $type, "$name.json");
    my $fh;
    if (!open $fh, '>', $full_path) {
        croak("Error opening for save $type config: $OS_ERROR");
    }
    if (!print {$fh} $json_text) {
        croak("Error saving $type configuration");
    }
    close $fh or croak("Cannot close $type config: $OS_ERROR");

    return;
} # end sub save

sub purge {
    my($self, $type, $name) = @_;
    return if !$self->{'dir'}; # Functionality disabled
    return if !$name;          # Name not specified - skip
    croak("Wrong config type: $type") if none { $type eq $_ } @VALID_DIRS;

    my $full_path = File::Spec->catfile($self->{'dir'}, $type, "$name.json");
    unlink $full_path;

    return;
} # end sub purge

