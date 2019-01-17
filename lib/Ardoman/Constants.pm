#!/usr/bin/perl

package Ardoman::Constants;

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.0.1');

use English qw( -no_match_vars );
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
use Readonly;

use base qw{ Exporter };
our @EXPORT_OK   = ();
our %EXPORT_TAGS = ();

$EXPORT_TAGS{'data'} = [qw{ $DATA_KEYS $DEFAULT_CHECK_DELAY }];
Readonly our $DATA_KEYS => {
    endpoint    => [qw{ host tls_verify ca_file cert_file key_file }],
    application => [
        qw{ image name id ports cmd env
            check_proc check_url check_delay }
    ],
};
Readonly our $DEFAULT_CHECK_DELAY => 7;

$EXPORT_TAGS{'symbols'} = [ qw{
        $EMPTY $SPACE $DOT $PERIOD $COMMA $COLON $DCOLON $AT
        $AT $NUMBER $DOLLAR $PERCENT $HYPEN $MINUS $DASH $PLUS
        }
];

Readonly our $EMPTY   => q{};
Readonly our $SPACE   => q{ };
Readonly our $DOT     => q{.};
Readonly our $PERIOD  => q{.};
Readonly our $COMMA   => q{,};
Readonly our $COLON   => q{:};
Readonly our $DCOLON  => q{::};
Readonly our $AT      => q{@};
Readonly our $NUMBER  => q{#}; # No way $HASH - it's busy for 'HASH'
Readonly our $DOLLAR  => q{$};
Readonly our $PERCENT => q{%};
Readonly our $HYPEN   => q{-};
Readonly our $MINUS   => q{-};
Readonly our $DASH    => q{--};
Readonly our $PLUS    => q{+};

$EXPORT_TAGS{'boolean'} = [ qw{
        $OK $ERROR $ON $OFF $YES $NO $TRUE $FALSE
        }
];

Readonly our $OK    => 1;
Readonly our $ERROR => $EMPTY;
Readonly our $ON    => 1;
Readonly our $OFF   => 0;
Readonly our $YES   => 1;
Readonly our $NO    => 0;
Readonly our $TRUE  => 1;
Readonly our $FALSE => $EMPTY;

$EXPORT_TAGS{'numerals'} = [ qw{
        $FIRST $ZERO $SECOND $ONE $TWO $LAST $PENULTIMATE
        }
];

Readonly our $FIRST       => 0;
Readonly our $ZERO        => 0;
Readonly our $SECOND      => 1;
Readonly our $ONE         => 1;
Readonly our $TWO         => 2;
Readonly our $LAST        => -1;
Readonly our $PENULTIMATE => -2;

$EXPORT_TAGS{'reftypes'} = [ qw{
        $NOTREF    $SCALAR    $ARRAY      $HASH
        $CODE      $REF       $GLOB       $LVALUE
        $FORMAT    $IO        $VSTRING    $REGEXP
        $REGEXP_RT
        }
];

Readonly our $NOTREF    => $EMPTY;
Readonly our $SCALAR    => 'SCALAR';
Readonly our $ARRAY     => 'ARRAY';
Readonly our $HASH      => 'HASH';
Readonly our $CODE      => 'CODE';
Readonly our $REF       => 'REF';
Readonly our $GLOB      => 'GLOB';
Readonly our $LVALUE    => 'LVALUE';
Readonly our $FORMAT    => 'FORMAT';
Readonly our $IO        => 'IO';
Readonly our $VSTRING   => 'VSTRING';
Readonly our $REGEXP    => 'Regexp';
Readonly our $REGEXP_RT => 'REGEXP'; # What returns by Scalar::Util(reftype)

$EXPORT_TAGS{'caller'} = [ qw{
        $CALLER_PACKAGE $CALLER_SUBROUTINE $CALLER_SUB $CALLER_WANT_ARRAY
        }
];

Readonly our $CALLER_PACKAGE    => 0;
Readonly our $CALLER_SUBROUTINE => 3;
Readonly our $CALLER_SUB        => 3;
Readonly our $CALLER_WANT_ARRAY => 5;

$EXPORT_TAGS{'log'} = [qw{ $ROOT_LOGGER $LOG4PERL_DEFAULT }];
Readonly our $ROOT_LOGGER      => $EMPTY;
Readonly our $LOG4PERL_DEFAULT => <<'LOG4PERL_DEFAULT';
log4perl.rootLogger             = OFF, Screen
log4perl.appender.Screen        = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr = 1
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %c [%P]:%p %m%n
LOG4PERL_DEFAULT

my(@all_words);
foreach my $tag (keys %EXPORT_TAGS) {
    push @all_words, @{ $EXPORT_TAGS{$tag} };
}

@EXPORT_OK = @all_words;
$EXPORT_TAGS{'all'} = [@all_words];

1;

__END__


