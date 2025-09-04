extends Node

var flexibility #0-1, impacts how likely the coach is to change strategies to accomodate the best players
var reactivity #0-1, impacts how likely the coach is to make substitutions or changes early in the game
var matchups #0-1, impacts how likely the coach is to pursue an enforcer vs thrower matchup or avoid a thrower vs enforcer
var violence #0-1, impacts how likely the coach is to look to injure opposing players
var injury_tolerance #0-1, impacts how likely the coach is to pull a player with a minor injury
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
var p_plan_players = ["Workhorse", "Enforcer", "Curveball"] #planned pitcher substitution scheme
var p_plan_time = [9, 6, 6] #how many pitches each player will play
var endurance_sub = 0.5 #how much max boost a player would need to be considered tired, modified by sub frequency for a position

func check_substitution_plans(myTeam: Team, pitchCount: int):
	var plan_player
	for count in p_plan_time:
		if count == pitchCount:
			plan_player = p_plan_players[p_plan_time.find(count)]
	#plan_player is now a string for the player typeinstead of the actual Player object
	#TODO: loop through the bullpen and find the most suitable replacement at that type
	

func check_need_substitution(myTeam: Team, otherTeam: Team, myScore: int, otherScore: int, pitchCount: int):
	var p_better = get_p_better(myTeam, otherTeam) #-1 my guy better, 0 even, 1 other guy better
	var p_tougher = get_p_tougher(myTeam, otherTeam) #-1 my guy tougher, 0 even, other guy tougher
	
	if pitchCount < GlobalSettings.pitch_limit/2: #early game, generally avoid making subs
		var sub_chance
		#TODO: check if any players are injured, measure their injury against injury_tolerance
		#TODO: if injured, see if we have enough players on the bench who can play their position
		var p_mismatch = p_better - p_tougher #TODO: math out how to calculate this
		#TODO: check p_mismatch against matchups rating and violence rating
		#TODO: only make a sub if the mismatch is severe or the coach has a serious tendency towards pushing the mismatch
		#TODO: make sure to save at least subs_reserve unless substituting for a major injury
	else:
		var sub_chance #late game, more likely to make a sub
		
		

func get_p_better(myTeam: Team, otherTeam: Team):
	if otherTeam.P.calculate_pitcher_overall() - myTeam.P.calculate_pitcher_overall() > 10: #their guy is better
		return 2
	elif otherTeam.P.calculate_pitcher_overall() - myTeam.P.calculate_pitcher_overall() > 5:
		return 1
	elif myTeam.P.calculate_pitcher_overall() - otherTeam.P.calculate_pitcher_overall() > 10:
		return -2
	elif myTeam.P.calculate_pitcher_overall() - otherTeam.P.calculate_pitcher_overall() > 5:
		return -1
	else:
		return 0
		
func get_p_tougher(myTeam: Team, otherTeam: Team):
	if otherTeam.P.attributes.toughness - myTeam.P.attributes.toughness > 10: #their guy is tougher
		return 2
	elif otherTeam.P.attributes.toughness- myTeam.P.attributes.toughness > 5:
		return 1
	elif myTeam.P.attributes.toughness - otherTeam.P.attributes.toughness > 10:
		return -2
	elif myTeam.P.attributes.toughness - otherTeam.P.attributes.toughness > 5:
		return -1
	else:
		return 0
			
func find_forward_sub(myTeam: Team, otherTeam: Team):
	#TODO: if the team's current lf strategy is 1:
	var game_weight #TODO: calculate based on score and pitches remaining
	#TODO: rank players based on overall in preferred role
	pass
	
