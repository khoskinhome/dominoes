package Dominoes::Util;
use strict; use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    true false trim
);

sub true  (){1}
sub false (){0}

sub trim {
    my ($txt) = @_;
    $txt =~ s/^\s*//;
    $txt =~ s/\s*$//;
    return $txt;
}


1;

