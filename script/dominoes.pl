#!/usr/bin/perl
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib/perl";

use Dominoes qw(
    main
);

use Getopt::Long;

my $help;
my $default_return;
GetOptions (
     "default-return"   => \$default_return,
     "help"             => \$help,

)
    or help("Error in command line arguments");

help() if $help;

sub help {
    my ($extra) = @_;

    my $help;
    ($help = <<"    EOHELP") =~ s/^ {4}//gm;
    Dominoes
    --------

    --help , this help

    --default-return

        In the main game loops this makes the
        'return' of an empty string have the defaults of :

            Always select 4 players.
            Always select "Auto Play" for the player.

    EOHELP

    die "$help\n$extra\n";

}

main($default_return);

