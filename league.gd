extends Node
class_name League

var league_name
var league_abbreviation
var league_level #B, A, AA, or AAA
var hub_point: Vector2
var teams:= [] #array of Teams
var season_length: int = 28
var promoting_league: League
var demoting_league: League
var num_playoff_champ: int = 3
var num_playoff_demote: int = 2
var num_promoted_playoff: int = 1 #championship
var num_demoted_playoff: int = 2 #from relegation playoff
var num_promoted_auto: int = 1 #from regular season position
var num_demoted_auto: int = 1 #from regular season position
var league_dues: int = 450
var cash_prize: int = 800
