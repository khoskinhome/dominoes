#!/usr/bin/perl
use strict; use warnings;

use Data::Dumper;

my $MAX_PIECE_NUM = scalar keys %{get_pieces()};

#use FindBin;
#use lib "$FindBin::Bin/../lib/perl";

my $verbose = 0;

sub main {

    # hash struct of all pieces.
    # my $pieces = get_pieces();
    # { piece_num => [1,0], ... }

    my $pieces_heap; # pieces left on the heap.
    # { piece_num => [1,0], ... }

    # the pieces that have been played.
    my @in_play_pieces = ();

    my $players_pieces = {};
    # { player_1 => { piece_num_1 => [0,0], ... },
    #   player_1 => { piece_num_2 => [1,0], ... },
    #   ...
    # }

    my $player_count;

    while (1) {
        print "----\nStarting Dominoes !\n";
        $player_count = how_many_players();


        # TODO randomly distribute pieces to players.
        init_distribute_pieces($pieces_heap, $players_pieces, $player_count);

        # work out player who has the highest double
        # They have to start.

        my $curr_player = 1;

        while (1){

            my $cur_ply_piece = player_select_piece($curr_player);




        }
    }
}

sub highest_double {
    my ($players_pieces) = @_;

    my $player_num;
    my $highest_double;

    for my $pi ( keys %$players_pieces ){




    }


}

sub init_distribute_pieces {
    my ($pieces_heap, $players_pieces, $player_count, $pickup_count) = @_;

    $pickup_count //= 7;

    $pieces_heap = get_pieces();

    $players_pieces = {};

    for (my $pi = 1; $pi <= $player_count; $pi++){

        $players_pieces->{$pi} = {};

        for (my $y=0 ; $y < $pickup_count; $y++){
            get_player_piece_from_heap ($pieces_heap, $players_pieces->{$pi});
        }

        print get_piece_string($players_pieces->{$pi}, $pi)."\n";
    }

    print "pieces heap ".get_piece_string($pieces_heap)."\n" if $verbose;
}

sub get_player_piece_from_heap {
    my ( $pieces_heap, $player_piece_single ) = @_;

    # On the randomisation could find a more random service,
    # rather than the perl rand builtin.
    # There's something i once saw as an internet service :
    # https://www.random.org/

    my @all_left = keys %$pieces_heap;

    if ( ! scalar @all_left ) {
        print "No pieces left on the heap\n";
        return;
    }

    my $sel = int rand(scalar @all_left);

    my $piece_ind = @all_left[$sel];

    my $player_sel_piece = delete $pieces_heap->{$piece_ind} ;

    $player_piece_single->{$piece_ind} = $player_sel_piece;
}

sub get_pieces {
    my $pieces = { };
    my $pcount = 0;
    for (my $i=0; $i <= 6; $i++){
        for (my $y=0; $y <= $i; $y++){
            $pcount++;

            # highest dots will always come first :
            $pieces->{$pcount} = [$i,$y];
        }
    }
    return $pieces;
}

sub player_select_piece {
    my ($player_num, $players_pieces, $in_play_pieces) = @_;

    my $msg = "Player [$player_num] please select your piece in 2 ".
              "digit format,\n".
              "  P to pick up a piece or Q to quit ... ";

    print $msg;

    while ( my $piece_str = <STDIN> ){
        # piece_str is a 2 digit num, not the hash key index !
        # i.e 00 or 12 or 21 (the same piece !)

        $piece_str = trim(lc($piece_str));

        my @piece_arr;

        # work out if they have a piece that can match,
        # offer those ?

        if ($piece_str !~ /^[0-6qp]{1,2}$/){
            print "\nInvalid response [$piece_str]\n";
            print $msg;
            next;
        }

        if ( @piece_arr = $piece_str =~ /^\d{2}$/ ) {

            # TODO swap around to highest "set of dots" first ?

        }
        elsif ($piece_str =~ /q+/ ){
            die "Exiting Game. Bye !\n";
        }
        elsif ($piece_str =~ /p+/ ){
            # TODO pick up a piece from the heap.
            die "TODO pickup piece. !\n";
            # call get_player_piece_from_heap
        }
        else{
            print "\nInvalid response [$piece_str]\n";
            print $msg;
            next;
        }

        # TODO check the players_pieces array.

        # Do they have the piece ?

        # Does it match on either end of the snake ?

        # Do they have any pieces that can match ?


        return $piece_str;
    };
}

sub how_many_players {
    my $msg = "How many players (2-4 or Q for quit) ? ";
    print $msg;
    while ( my $player_count = <STDIN> ){

        $player_count = trim(lc($player_count));

        if ($player_count !~ /^[2-4q]$/){
            print "\nInvalid response [$player_count]\n";
            print $msg;
            next;
        }
        if ($player_count eq "q" ){
            die "Exiting Game. Bye !\n";
        }
        return $player_count;
    };
}

sub get_piece_string {
    my ( $piece_struct, $player_num ) = @_;

    my $str = "";
    for my $psi ( sort keys %$piece_struct ){

        $str .= sprintf("[%d-%d] ",
                    $piece_struct->{$psi}[0],
                    $piece_struct->{$psi}[1],
                );
    }

    $str = trim ( $str );

    if ($player_num) {
        $str = sprintf( "Player %d pieces : %s", $player_num, $str);
    }

    return $str;
}

sub trim {
    my ($txt) = @_;
    $txt =~ s/^\s*//;
    $txt =~ s/\s*$//;
    return $txt;
}

main();
