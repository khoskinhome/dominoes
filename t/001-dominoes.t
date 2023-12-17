use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib/perl";

use Data::Dumper ;
use Test::Most;


use_ok 'Dominoes';
use_ok 'Dominoes::Util';


use Dominoes::Util qw(
    true false trim
);

use Dominoes qw();


ok (trim("  hi world ") eq "hi world", "trim works on str param");

# TODO a whole lot more unit testing on all subs.

ok ( defined Dominoes::dots_can_go_left([[0,3],[3,3],[3,4]], [0,3]) ,"dots_can_go_left() T1");
ok ( defined Dominoes::dots_can_go_left([[0,3],[3,3],[3,4]], [3,0]) ,"dots_can_go_left() T2");
ok ( ! defined Dominoes::dots_can_go_left([[0,3],[3,3],[3,0]], [3,4]) ,"dots_can_go_left() T3");
ok ( ! defined Dominoes::dots_can_go_left([[0,3],[3,3],[3,0]], [4,3]) ,"dots_can_go_left() T4");

ok ( defined Dominoes::dots_can_go_right([[0,3],[3,3],[3,4]], [3,4]) ,"dots_can_go_right() T1");
ok ( defined Dominoes::dots_can_go_right([[0,3],[3,3],[3,4]], [4,3]) ,"dots_can_go_right() T2");
ok ( defined Dominoes::dots_can_go_right([[0,3],[3,3],[3,0]], [4,0]) ,"dots_can_go_right() T3");
ok ( ! defined Dominoes::dots_can_go_right([[0,3],[3,3],[3,0]], [3,4]) ,"dots_can_go_right() T4");

ok ( Dominoes::get_piece_string({1=>[0,2]}) eq "[0-2]", "get_piece_string() T1");
ok ( Dominoes::get_piece_string({1=>[0,2]}, 1) eq "Player [1] pieces : [0-2]",
     "get_piece_string() T2");

ok ( Dominoes::get_in_play_string([[0,2],[2,3]]) eq "[0-2] [2-3]", "get_in_play_string() T1");

like ( Dominoes::tally_up_scores({ 1=> { 1=>[2,3], 2=> [4,5] }}) ,
    qr/Player \[1\] . Spots count \[ 14\]/, "tally_up_scores() T1");

done_testing();


