package Ardoman::Docker::Handler;

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.0.2');

use English qw( -no_match_vars );
use Carp;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;

$Carp::Verbose = 1; ## no critic (Variables::ProhibitPackageVars)

use Readonly;
use JSON;

use List::Util qw{ pairmap };

use LWP::UserAgent qw{};

my(%METHOD, %PREFIX, %SUFFIX, %USE_ID);

map { $USE_ID{$_} = 1 } qw{ start stop inspect remove delete top };

map { $METHOD{$_} = 'get' } qw{ version select inspect top };
map { $METHOD{$_} = 'post' } qw{ create start stop  };
map { $METHOD{$_} = 'delete' } qw{ delete };

# All except version (for now), so just use grep
map { $PREFIX{$_} = 'containers' } grep { $_ ne 'version' } keys %METHOD;

map { $SUFFIX{$_} = 'json' } map qw { select inspect };
$SUFFIX{'version'} = 'version';
$SUFFIX{'create'}  = 'create';
$SUFFIX{'start'}   = 'start';
$SUFFIX{'stop'}    = 'stop';
$SUFFIX{'top'}     = 'top';

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

    # If the argument is an odd number then the first is the host
    my $host = @args % 2 ? shift @args : undef;

    my %conf = @args;
    $conf{'host'} //= $host // $ENV{DOCKER_HOST};

    croak('Required host argument missing') if !$conf{'host'};

    my $ua = LWP::UserAgent->new();
    croak('UserAgent creation failure') if !$ua;

    $ua->agent(__PACKAGE__ . q{/} . $VERSION->numify());
    $ua->default_header('Content-Type' => 'application/json; charset=utf-8');

    my $self = bless {
        conf => \%conf,
        ua   => $ua,   # TODO Implement TLS options
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
sub request {
    my($self, $action, $query, $post) = @_;

    croak('Required action argument missing') if !$action;

    my $method = $METHOD{$action};
    croak("Unrecognized/unsupported action: $action") if !$method;

    my $url = $self->{'conf'}->{'tls_verify'} ? 'https://' : 'http://';
    $url .= _prepare_url($self->{'conf'}->{'host'}, $action, $query);

    my $ua_resp;
    if ($method eq 'post' && ref $post eq 'HASH') {
        my $content = _to_json($post, { pretty => 1 });
        $ua_resp = $self->{'ua'}->$method($url, Content => $content);
    }
    else {
        $ua_resp = $self->{'ua'}->$method($url);
    }
    croak('Empty response returned') if !$ua_resp;

    if (!$ua_resp->is_success()) {
        croak('API Error: ' . $ua_resp->status_line());
    }

    my $api_resp        = {};
    my $decoded_content = $ua_resp->decoded_content();
    if ($decoded_content) {
        $api_resp = _from_json($decoded_content, { relaxed => 1 });
    }

    if ($action eq 'select') {
        croak('Wrong resp select: not an array') if ref $api_resp ne 'ARRAY';
        croak('More then 1 returned by select')  if scalar @{$api_resp} > 1;

        $api_resp = pop @{$api_resp};
    }

    croak('Wrong resp from API: not a hash') if ref $api_resp ne 'HASH';

    return $api_resp;
} # end sub request

sub _prepare_url {
    my($host, $action, $query) = @_;

    my @url_parts = $host;

    if ($PREFIX{$action}) { push @url_parts, $PREFIX{$action} }

    if ($USE_ID{$action}) {
        croak("Missing required id for action $action") if !$query->{'id'};
        push @url_parts, delete $query->{'id'};
    }

    if ($SUFFIX{$action}) { push @url_parts, $SUFFIX{$action} }

    my $url = join q{/}, @url_parts;

    if (ref $query eq 'HASH') {
        foreach my $key (keys %{$query}) {
            if (ref $query->{$key}) {
                $query->{$key} = _to_json($query->{$key});
            }
        }
        my $query_str = join q{&}, pairmap { "$a=$b" } %{$query};
        if ($query_str) {
            $url .= q{?} . $query_str;
        }
    } # end if (ref $query eq 'HASH')

    return $url;
} # end sub _prepare_url

sub _to_json {
    my($data, $json_opts) = @_;

    $json_opts //= {};
    my $json;

    if (!eval { $json = to_json($data, $json_opts) }) {
        croak("JSON encoding error: $EVAL_ERROR");
    }

    return $json;
} # end sub _to_json

sub _from_json {
    my($json, $json_opts) = @_;

    $json_opts //= {};
    my $data;

    if (!eval { $data = from_json($json, $json_opts) }) {
        croak("JSON decoding error: $EVAL_ERROR");
    }

    return $data;
} # end sub _from_json

1;

__END__

