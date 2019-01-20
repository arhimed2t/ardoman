package Ardoman::Docker::Handler;

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.0.3');

use English qw( -no_match_vars );
use Carp;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;

use JSON;

use List::Util qw{ pairmap };

use LWP::UserAgent qw{};

my(%METHOD, %PREFIX, %SUFFIX, %USE_ID);

for (qw{ start stop remove delete top }) { $USE_ID{$_} = 1 }

for (qw{ version select top }) { $METHOD{$_} = 'get' }
for (qw{ create start stop  }) { $METHOD{$_} = 'post' }
$METHOD{'delete'} = 'delete';

for (keys %METHOD) {
    next if $_ eq 'version';
    $PREFIX{$_} = 'containers';
}

$SUFFIX{'select'}  = 'json';
$SUFFIX{'version'} = 'version';
$SUFFIX{'create'}  = 'create';
$SUFFIX{'start'}   = 'start';
$SUFFIX{'stop'}    = 'stop';
$SUFFIX{'top'}     = 'top';

### CLASS METHOD ############################################################
# Usage      : Ardoman::Docker::Handler->new( \%endpoint_configuration );
# Purpose    : Create instance of this class to get access to the EP
# Returns    : Instance
# Parameters : 1st unpaired argument may be 'host', otherwise supports only->
#            : hash with named arguments:
#            :      host - hostname or address, with required port to EP
#            :      also accepts $ENV{DOCKER_HOST} if all above do not set
# Throws     : Missing resuired argument 'host' (in any 3 way)
#            : LWP::UserAgent creation failure (returned empty)
# Comments   : TLS-related option ignore in version v0.0.3
# See Also   : Ardoman::Docker::API, Ardoman::Docker::Container
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
# Usage      : $o->request($action, $query, $post)
# Purpose    : Prepare and send request to the EP
# Returns    : decoded API response as hash (in success)
# Parameters : $action - what to do (create start stop delete select top etc)
#            : $query - query part of request as hash (id name filters etc)
#            : $post - body of reuest as hash (creation parameters for now)
# Throws     : Response from EP not 'is_success' - other tnan 2xx
#            : Empty response returned
#            : Response isn't hash
#            : Missing action argument
#            : Wrong action (unrecognized)
#            : For select action: not an array was returned
#            :      not one container was returned (not found, or found > 1)
# Comments   : none
# See Also   : _prepare_url
sub request {
    my($self, $action, $query, $post) = @_;

    croak('Required action argument missing') if !$action;

    my $method = $METHOD{$action};
    croak("Unrecognized/unsupported action: $action") if !$method;

    #my $url = $self->{'conf'}->{'tls_verify'} ? 'https://' : 'http://';
    my $url = 'http://';
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
        croak('More then 1 returned by select')  if scalar @{$api_resp} != 1;

        $api_resp = pop @{$api_resp};
    }

    croak('Wrong resp from API: not a hash') if ref $api_resp ne 'HASH';

    return $api_resp;
} # end sub request

############################################## INTERNAL UTILITY #############
# Usage      : _prepare_url($action, $query)
# Purpose    : Prepare and collect URR to API based on $action and $query
# Returns    : URL as string
# Parameters : $action - what to do (create start stop delete select top etc)
#            : $query - query part of request as hash (id name filters etc)
# Throws     : If request must contain ID, but it didn't pass in $query
# Comments   : none
# See Also   : request
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

############################################## INTERNAL UTILITY #############
# Usage      : _to_json( $data_as_ref [, \%json_options ])
# Purpose    : Convert to JSON perl object with some options
# Returns    : JSON as string
# Parameters : $data_as_ref - reference to perl stucture to be encoded
#            : \%json_options - optional options, hash, e.g. { pretty => 1 }
# Throws     : JSON encoding errors
# Comments   : none
# See Also   : JSON
sub _to_json {
    my($data, $json_opts) = @_;

    $json_opts //= {};
    my $json;

    if (!eval { $json = to_json($data, $json_opts) }) {
        croak("JSON encoding error: $EVAL_ERROR");
    }

    return $json;
} # end sub _to_json

############################################## INTERNAL UTILITY #############
# Usage      : _from_json( $json_as_str [, \%json_options ])
# Purpose    : Convert from JSON to perl object with some options
# Returns    : Reference to perl structure
# Parameters : $json_as_str - string with JSON to be decoded
#            : \%json_options - optional options, hash, e.g. { relaxed => 1 }
# Throws     : JSON decoding errors
# Comments   : none
# See Also   : JSON
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

