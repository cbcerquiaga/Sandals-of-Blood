extends Node

var flexibility #0-1, impacts how likely the coach is to change strategies to accomodate the best players
var reactivity #0-1, impacts how likely the coach is to make substitutions or changes early in the game
var defense_1 #preferred defense strategy
var defense_2 #backup strategy if defense 1 is not working
var lf_role_1 #preferred role for the left forward
var lf_role_2 #second choice role for the left forward
var lf_role_3
var rf_role_1
var rf_role_2
var rf_role_3
var fav_type_k #favorite type of keeper
var fav_weight_k #0-1 how much the coach will look for that type of player vs the best available
var fav_type_lg
var fav_weight_lg
var fav_type_rg
var fav_weight_rg
var mix_f_roles: bool = false #whether the team will use lf role 1 with an rf role other than 1
var subs_reserve: int = 1 #how many substitutes the coach will leave in reserve in case of an injury
var max_platoon: int = 2 #how many players the coach will substitute at once
var sub_frequency_p: float = 0.7 # 0-1, how often the coach will substitute pitchers
var sub_frequency_g: float = 0.2
var sub_frewuency_f: float = 0.3
var sub_frequency_k: float = 0.1
var p_matchups = { #F for fastball, C for curveball, W for workhorse, E for enforcer; first is us, second is them
	"FvF": true,
	"FvC": true,
	"FvW": true,
	"FvE": false,
	"CvF": true,
	"CvC": true,
	"CvW": true,
	"CvE": false,
	"WvF": true,
	"WvC": false,
	"WvW": true,
	"WvE": true,
	"EvF": true,
	"EvC": true,
	"EvW": true,
	"EvE": true
}
var p_plan_players = ["W", "E", "C"] #planned pitcher substitution scheme
var p_plan_time = [9, 6, 6] #how many pitches each player will play
var endurance_sub = 0.5 #how much max boost a player would need to be considered tired, modified by sub frequency for a position

func find_forward_sub():
	#TODO: if the team's current lf strategy is 1:
	var game_weight #TODO: calculate based on score and pitches remaining
	#TODO: rank players based on overall in preferred role
	pass
