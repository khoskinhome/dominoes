#!/usr/bin/perl
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib/perl";

use Data::Dumper;

use Exception::Class qw(
    ExceptNoDouble
    ExceptNoPieces
    ExceptCannotPlayPiece
    ExceptGameOver
    ExceptPlayerNext
    ExceptKickOffGame
);

use Nice::Try;

use Dominoes::Util qw(
    true false trim
);

my $separator = "----------------";

sub main {
    while (true) {
        play_one_game();
    }
}

sub play_one_game {
    print "$separator\nStarting Dominoes !\n";
    my $player_count = how_many_players();

    my ($player_num, $double_piece_ind);

    my $next_player = sub {
        $player_num ++;
        $player_num = 1 if $player_num > $player_count;
    };

    my $in_play_pieces = [];
    # ^^
    # the pieces that have been played.
    # [ [0,0], [1,0] , ... ]

    my $pieces_heap = get_pieces();
    # ^^
    # { piece_ind => [1,0], ... }


    my $all_players_pieces = {};
    # ^^
    # { player_1 => { piece_num_1 => [0,0], ... },
    #   player_1 => { piece_num_2 => [1,0], ... },
    #   ...
    # }
    distribute_pieces($pieces_heap, $all_players_pieces, $player_count);


    my $found_double = false;
    while ( ! $found_double ){
        try {
            ($player_num, $double_piece_ind) =
                                    highest_double($all_players_pieces);

            $found_double = true;

            add_piece_in_play($in_play_pieces,
                              $player_num,
                              $all_players_pieces->{$player_num},
                              $double_piece_ind,
                              undef, # don't really need to do this !
                            );

            $next_player->();

        }
        catch ($e) {
            print "No player had a double, all getting an extra piece\n";
            distribute_pieces($pieces_heap, $all_players_pieces,
                              $player_count,1);
        };
    }

    my $next_count = 0;
    my $game_in_play = true;
    while ($game_in_play){
        # main play game loop.
        try {
            player_select_piece(
                            $pieces_heap, $in_play_pieces,
                            $player_num,
                            $all_players_pieces->{$player_num},
                        );
            $next_player->();
            $next_count = 0;
        }
        catch (ExceptKickOffGame $e) {
            print "Kick Off A New Game\n";
            $game_in_play = false;
        }
        catch (ExceptGameOver $e) {
            tally_up_scores($all_players_pieces, $player_num);
            $game_in_play = false;
        }
        catch (ExceptPlayerNext $e) {
            $next_player->();
            $next_count ++;

            if ($next_count >= $player_count){
                tally_up_scores($all_players_pieces);
                $game_in_play = false;
            }
        }
        catch ($e) {
            warn "Unhandled Fatal Exception $e\n";
            exit 1;
        };
    }
}

sub add_piece_in_play {
    my ($in_play_pieces, $player_num,
        $single_player_pieces, $piece_ind, $left_or_right) = @_;

    if ( ! scalar @$in_play_pieces ) {
        # beginning of game, check it's a double.

        my $player_piece = delete $single_player_pieces->{$piece_ind} ;

        if ( $player_piece->[0] != $player_piece->[1] ){
            print "Fatal programming error trying to beginning of ".
                    "game with Double\n";
            exit 1;
        }

        printf( "$separator\nPlayer %d started the game with [%d-%d]\n",
              $player_num, $player_piece->[0], $player_piece->[1]);


        push @$in_play_pieces, $player_piece;

        print "Board : ".get_in_play_string($in_play_pieces)."\n";

    }
    else {
        my $ply_piece = $single_player_pieces->{$piece_ind};

        if ( ! $ply_piece ) {
            ExceptNoPieces->throw(
               sprintf("Player [%d] doesn't have piece with index [%d]",
                        $player_num, $piece_ind));
        }

        my ($can_be_played, $can_be_played_index) =
            pieces_can_be_played({$piece_ind => $ply_piece}, $in_play_pieces);

        if ( ! scalar @$can_be_played_index
            || $can_be_played_index->[0] != $piece_ind
        ){
            ExceptCannotPlayPiece->throw(
                sprintf("Player [%d] Cannot Play [%d-%d]",
                        $player_num, @$ply_piece));
        }

        $left_or_right //= "r";
        if ($left_or_right !~ /^[lr]$/){
            print "Fatal programming error. left_or_right not valid\n";
            exit 1;
        }

        my $push_piece_right = sub {
            my $dots = dots_can_go_right($in_play_pieces, $ply_piece);
            return false if ! defined $dots;

            $ply_piece = delete $single_player_pieces->{$piece_ind};

            if ( $ply_piece->[0] != $dots ){
                @$ply_piece = reverse @$ply_piece;
            }
            push @$in_play_pieces, $ply_piece;
            return true;
        };

        my $push_piece_left = sub {
            my $dots = dots_can_go_left($in_play_pieces, $ply_piece);
            return false if ! defined $dots;

            $ply_piece = delete $single_player_pieces->{$piece_ind};

            if ( $ply_piece->[1] != $dots ){
                @$ply_piece = reverse @$ply_piece;
            }
            unshift @$in_play_pieces, $ply_piece;
            return true;
        };

        if ($left_or_right eq 'r'){
            return if $push_piece_right->();
            return $push_piece_left->();
        }
        elsif ($left_or_right eq 'l'){
            return if $push_piece_left->();
            return $push_piece_right->();
        }
    }
}

sub highest_double {
    my ($all_players_pieces) = @_;

    my $player_num;
    my $highest_double = -1;
    my $double_piece_ind;

    for my $pi ( keys %$all_players_pieces ){
        print get_piece_string($all_players_pieces->{$pi}, $pi)."\n";

        my $single_player_pieces = $all_players_pieces->{$pi};

        for my $piece_ind ( keys %$single_player_pieces ){
            my $piece = $single_player_pieces->{$piece_ind};

            if ( $piece->[0] == $piece->[1]
                && $piece->[0] > $highest_double
            ){
                $player_num = $pi;
                $highest_double = $piece->[0];
                $double_piece_ind = $piece_ind;
            }
        }
    }

    ExceptNoDouble->throw("No Player has a double") if ! $player_num;

    return ($player_num, $double_piece_ind);
}

sub distribute_pieces {
    my ($pieces_heap, $all_players_pieces, $player_count, $pickup_count) = @_;

    $pickup_count //= 7;

    for (my $pi = 1; $pi <= $player_count; $pi++){

        $all_players_pieces->{$pi} = {};

        for (my $y=0 ; $y < $pickup_count; $y++){
            get_player_piece_from_heap($pieces_heap, $all_players_pieces->{$pi});
        }
    }
}

sub get_player_piece_from_heap {
    my ( $pieces_heap, $single_player_pieces ) = @_;

    # On the randomisation could find a more random service,
    # rather than the perl rand builtin.
    # I have seen this an internet service https://www.random.org/

    my @all_left = keys %$pieces_heap;

    if ( ! scalar @all_left ) {
        ExceptNoPieces->throw("No pieces left on the heap");
    }

    my $sel = int rand(scalar @all_left);

    my $piece_ind = $all_left[$sel];

    my $player_sel_piece = delete $pieces_heap->{$piece_ind};

    $single_player_pieces->{$piece_ind} = $player_sel_piece;
}

sub get_pieces {
    my $pieces = { };
    my $piece_ind = 0;
    for (my $i=0; $i <= 6; $i++){
        for (my $y=0; $y <= $i; $y++){
            $piece_ind++;

            # highest dots will always come first :
            $pieces->{$piece_ind} = [$i,$y];
        }
    }
    return $pieces;
}

sub player_select_piece {
    my ( $pieces_heap, $in_play_pieces,
         $player_num,  $single_player_pieces ) = @_;

    printf ("$separator\nPlayer [%d]'s turn ...\n\n", $player_num);

    my $pieces_can_be_played_str = pieces_can_be_played_string(
                                    $single_player_pieces, $in_play_pieces);

    my $msg = sprintf("Player [%d] you have the pieces : \n  %s\n".
                "The in play board is \n  %s\n".
                "You can play :\n %s\n".
                "Please Enter either :\n".
                "  Your piece in 2 digit format ( i.e. '02' or '20' )\n".
                "     Optionally prefix with L or R to specify what end".
                    " of the in-play-board. i.e 'L02'".
                    " (defaults to 'R')\n".
                "  P to pick up a piece from the heap\n".
                "  N to pass to next player (because you can't play a piece)\n".
                "  A 'auto' play !\n".
                "  K to 'kick off' game again\n".
                "  Q to quit game\n".
                "Enter ? :",
                $player_num,
                get_piece_string($single_player_pieces),
                get_in_play_string($in_play_pieces),
                $pieces_can_be_played_str,
            );

    my $input;
    my $err_msg = '';

    while (true){

        print "\n$err_msg\n\n" if $err_msg;
        $err_msg = '';
        print $msg;
        $input = <STDIN> ;

        $input = trim(lc($input));

        my @inp_arr;

        if ($input !~ /^[0-6klarnqp]{1,3}$/){
            $err_msg = sprintf ("Player [%d] Invalid response [%s]",
                      $player_num, $input,
                    );
            next;
        }

        if ( $input =~ /k+/ ){
            # kick off game again.
             ExceptKickOffGame->throw("Kick Off Game Again");
        }
        elsif ( $input =~ /a+/ ){
            # Auto play 

            my (undef, $can_be_played_index) =
                        pieces_can_be_played($single_player_pieces, $in_play_pieces);

            if ( scalar @$can_be_played_index){
                # Auto : player can play something.
                try {
                    add_piece_in_play($in_play_pieces, $player_num,
                        $single_player_pieces, $can_be_played_index->[0], undef);
                }
                catch ($e) {
                    $err_msg =$e;
                    next;
                };

                if ( ! scalar keys %$single_player_pieces ){
                    ExceptGameOver->throw(sprintf("Player [%d] Wins !",
                                          $player_num));
                }
                return;
            }
            elsif (scalar keys %$pieces_heap ){
                # Auto : pick up a piece from the heap.
                try {
                    get_player_piece_from_heap($pieces_heap, $single_player_pieces );
                }
                catch ($e) {
                    $err_msg ="Player [$player_num] $e";
                    next;
                };
                return;
            }
            else {
                # Auto : Do a "next" player
                ExceptPlayerNext->throw("Player [$player_num] did next");
            }

            $err_msg = "AUTO Play not yet implemented";
            next;

        }
        elsif ( $input =~ /n+/ ){
            # pass to next player (because no pieces are matching)
            if ( $pieces_can_be_played_str ){
                $err_msg ="Player [$player_num] can play a piece !";
                next;
            }

            if (scalar keys %$pieces_heap ){
                $err_msg ="Player [$player_num] can pickup a piece !";
                next;
            }

            ExceptPlayerNext->throw("Player [$player_num] did next");
        }
        elsif ( $input =~ /p+/ ){
            # pick up a piece from the heap.
            try {
                get_player_piece_from_heap($pieces_heap, $single_player_pieces );
            }
            catch ($e) {
                $err_msg ="Player [$player_num] $e";
                next;
            };
            return;
        }
        elsif ( $input =~ /q+/ ){
            warn "Exiting Game. Bye !\n";
            exit 0;
        }
        elsif ( @inp_arr = $input =~ /^([lr])?(\d)(\d)$/ ) {

            my $piece_ind;
            try {
                $piece_ind = player_has_piece($single_player_pieces,
                                              [$inp_arr[1],$inp_arr[2]]);
            }
            catch ($e) {
                $err_msg = $e;
                next;
            };

            try {
                add_piece_in_play($in_play_pieces, $player_num,
                    $single_player_pieces, $piece_ind, $inp_arr[0]);
            }
            catch ($e) {
                $err_msg =$e;
                next;
            };

            if ( ! scalar keys %$single_player_pieces ){
                ExceptGameOver->throw(sprintf("Player [%d] Wins !",
                                      $player_num));
            }

            return;
        }

        $err_msg = sprintf ("Player [%d] Invalid response [%s]",
                            $player_num, $input);
    }
}

sub player_has_piece {
    my ($single_player_pieces, $piece_arr) = @_;

    for my $piece_ind ( keys %$single_player_pieces ){

        my $ply_piece = $single_player_pieces->{$piece_ind};

        if ((   $ply_piece->[0] == $piece_arr->[0]
             && $ply_piece->[1] == $piece_arr->[1]
            )
          ||
            (   $ply_piece->[0] == $piece_arr->[1]
             && $ply_piece->[1] == $piece_arr->[0]
            )
        ){
            return $piece_ind;
        }
    }

    ExceptNoPieces->throw(
        sprintf("Player doesn't have piece [%d-%d]",@$piece_arr));

}

sub pieces_can_be_played_string {
    my($single_player_pieces, $in_play_pieces) = @_;

    my ($can_be_played, undef) =
                pieces_can_be_played($single_player_pieces, $in_play_pieces);

    my $can_be_played_str = '';
    for my $piece (@$can_be_played){
        $can_be_played_str .= sprintf("[%d-%d] ", @$piece);
    }
    return trim($can_be_played_str);
}

sub pieces_can_be_played {
    my($single_player_pieces, $in_play_pieces) = @_;

    ExceptNoPieces->throw("No pieces in play !")
        if ! scalar @$in_play_pieces;

    my @can_be_played;
    my @can_be_played_indexes;

    my $left_dots_in_play = $in_play_pieces->[0][0];
    my $right_dots_in_play =
                $in_play_pieces->[$#$in_play_pieces][1];


    for my $piece_ind ( keys %$single_player_pieces ){

        my $piece_arr = $single_player_pieces->{$piece_ind};

        if (    $piece_arr->[0] == $left_dots_in_play
            ||  $piece_arr->[1] == $left_dots_in_play
            ||  $piece_arr->[0] == $right_dots_in_play
            ||  $piece_arr->[1] == $right_dots_in_play
        ){
            push @can_be_played, $piece_arr;
            push @can_be_played_indexes, $piece_ind;
        }
    }

    return ( \@can_be_played, \@can_be_played_indexes );
}

sub dots_can_go_left {
    my ($in_play_pieces, $piece_arr) = @_;
    # can return 0 for a "can play".
    # undef is returned for "Can't play".

    my $left_dots_in_play = $in_play_pieces->[0][0];
    if (    $piece_arr->[0] == $left_dots_in_play
        ||  $piece_arr->[1] == $left_dots_in_play
    ){
        return $left_dots_in_play;
    }

    return;
}

sub dots_can_go_right {
    my ($in_play_pieces, $piece_arr) = @_;
    # can return 0 for a "can play".
    # undef is returned for "Can't play".

    my $right_dots_in_play =
                $in_play_pieces->[$#$in_play_pieces][1];

    if (    $piece_arr->[0] == $right_dots_in_play
        ||  $piece_arr->[1] == $right_dots_in_play
    ){
        return $right_dots_in_play;
    }

    return;
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

    $str = trim( $str );
    if ($player_num) {
        $str = sprintf( "Player %d pieces : %s", $player_num, $str);
    }

    return $str;
}

sub get_in_play_string {
    my ( $in_play_pieces ) = @_;

    my $str  = '';
    for my $piece ( @$in_play_pieces ){

        $str .= sprintf( "[%d-%d] ",$piece->[0], $piece->[1]);
    }
    return $str;
}

sub tally_up_scores {
    my ($all_players_pieces, $player_out_first) = @_;

    my $player_scores = {};

    for my $pi ( keys %$all_players_pieces ){
        $player_scores->{$pi} = 0;
        my $single_player_pieces = $all_players_pieces->{$pi};

        for my $piece_ind ( keys %$single_player_pieces ){
            my $piece_arr = $single_player_pieces->{$piece_ind};
            $player_scores->{$pi} += $piece_arr->[0];
            $player_scores->{$pi} += $piece_arr->[1];
        }
    }

    print "Game Result is (Winner at the top) :\n";
    for my $pi ( sort { $player_scores->{$a} <=> $player_scores->{$b} }
                 keys %$player_scores
    ){
        printf("Player [%d] . Spots count [%d]\n",
               $pi, $player_scores->{$pi});
    }
}

main();
