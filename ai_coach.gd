# ai_coach.gd
extends Node

var eccentricity: float #0-1, impacts chance of making random decisions
var flexibility: float #0-1, impacts how likely the coach is to change strategies to accommodate the best players
var reactivity: float #0-1, impacts how likely the coach is to make substitutions or changes early in the game
var matchups: float #0-1, impacts how likely the coach is to pursue an enforcer vs thrower matchup or avoid a thrower vs enforcer
var violence: float #0-1, impacts how likely the coach is to look to injure opposing players
var injury_tolerance: float #0-1, impacts how likely the coach is to pull a player with a minor injury
var defense_1: String #preferred defense strategy
var defense_2: String #backup strategy if defense 1 is not working
var defense_flexibility: float = 0.5 #0-1 tendency to change defenses if scored on in consecutive plays
var lf_role_1: String #preferred role for the left forward
var lf_role_2: String #second choice role for the left forward
var lf_role_3: String
var rf_role_1: String
var rf_role_2: String
var rf_role_3: String
var fav_type_k: String #favorite type of keeper
var fav_weight_k: float #0-1 how much the coach will look for that type of player vs the best available
var fav_type_lg: String
var fav_weight_lg: float
var fav_type_rg: String
var fav_weight_rg: float
var mix_f_roles: bool = false #whether the team will use lf role 1 with an rf role other than 1
var subs_reserve: int = 1 #how many substitutes the coach will leave in reserve in case of an injury
var max_platoon: int = 2 #how many players the coach will substitute at once
var sub_frequency_p: float = 0.7 #0-1, how often the coach will substitute pitchers
var sub_frequency_g: float = 0.2
var sub_frequency_f: float = 0.3
var sub_frequency_k: float = 0.1
var p_plan_players: Array = ["Workhorse", "Enforcer", "Curveball"] #planned pitcher substitution scheme
var p_plan_time: Array = [9, 6, 6] #how many pitches each player will play
var endurance_sub: float = 0.5 #how much max boost a player would need to be considered tired, modified by sub frequency for a position

var consecutive_goals_against: int = 0
var last_goal_pitch: int = -1
var current_defense: String
var current_lf_role: String
var current_rf_role: String

var forward_role_preferences = {
	"Classic Forward": {"scorer": 0.4, "anti_keeper": 0.4, "support": 0.2, "skull_cracker": 0.1},
	"Rusher": {"scorer": 0.1, "anti_keeper": 0.7, "support": 0.1, "skull_cracker": 0.1},
	"Shooting Forward": {"scorer": 0.8, "anti_keeper": 0.1, "support": 0.2, "skull_cracker": 0.0},
	"Rebounder": {"scorer": 0.4, "anti_keeper": 0.1, "support": 0.4, "skull_cracker": 0.2},
	"Attacking Forward": {"scorer": 0.4, "anti_keeper": 0.4, "support": 0.1, "skull_cracker": 0.1},
	"Target Forward": {"scorer": 0.2, "anti_keeper": 0.2, "support": 0.5, "skull_cracker": 0.1},
	"Support Forward": {"scorer": 0.1, "anti_keeper": 0.2, "support": 0.6, "skull_cracker": 0.1},
	"Roving Menace": {"scorer": 0.0, "anti_keeper": 0.6, "support": 0.1, "skull_cracker": 0.2},
	"Pick and Roller": {"scorer": 0.2, "anti_keeper": 0.5, "support": 0.2, "skull_cracker": 0.1},
	"Pick and Popper": {"scorer": 0.4, "anti_keeper": 0.2, "support": 0.3, "skull_cracker": 0.1},
	"Defensive Forward": {"scorer": 0.1, "anti_keeper": 0.3, "support": 0.6, "skull_cracker": 0.2},
	"Goon": {"scorer": 0.0, "anti_keeper": 0.1, "support": 0.2, "skull_cracker": 0.8}
}

var violence_roles = ["Roving Menace", "Goon"] #if the game is definitely a loss, put fighters as goons and non-fighters as menaces

func _ready():
	current_defense = defense_1
	current_lf_role = lf_role_1
	current_rf_role = rf_role_1

func make_coaching_decisions(myTeam: Team, otherTeam: Team, myScore: int, otherScore: int, pitchCount: int, pitches_remaining: int) -> Dictionary:
	var decisions = {
		"substitutions": [],
		"strategy_changes": {},
		"forward_role_changes": {}
	}

	if check_defense_change_needed(myScore, otherScore, pitchCount):
		decisions["strategy_changes"]["defense"] = get_next_defense()
		consecutive_goals_against = 0
	
	var planned_subs = check_substitution_plans(myTeam, pitchCount)
	if planned_subs:
		decisions["substitutions"].append_array(planned_subs)
	
	var needed_subs = check_need_substitution(myTeam, otherTeam, myScore, otherScore, pitchCount, pitches_remaining)
	if needed_subs:
		decisions["substitutions"].append_array(needed_subs)
	
	if decisions["substitutions"].size() > 0:
		var forward_role_changes = adjust_forward_roles_on_subs(myTeam, decisions["substitutions"])
		if forward_role_changes:
			decisions["forward_role_changes"] = forward_role_changes
	
	if violence > 0 and is_losing_badly(myScore, otherScore, pitches_remaining):
		var violence_subs = make_violence_subs(myTeam)
		if violence_subs:
			decisions["substitutions"].append_array(violence_subs)
			# Check how good our players are at fighting, make them menaces if they're not tough enough
			var lf_violence = get_player_violence_rating(myTeam.LF)
			var rf_violence = get_player_violence_rating(myTeam.RF)
			
			if lf_violence > 60:
				decisions["forward_role_changes"]["LF"] = "Goon"
			else:
				decisions["forward_role_changes"]["LF"] = "Roving Menace"
				
			if rf_violence > 60:
				decisions["forward_role_changes"]["RF"] = "Goon"
			else:
				decisions["forward_role_changes"]["RF"] = "Roving Menace"
	return decisions

func check_defense_change_needed(myScore: int, otherScore: int, pitchCount: int) -> bool:
	if pitchCount > last_goal_pitch + 3:
		consecutive_goals_against = 0

	# Random change based on eccentricity
	if randf() < eccentricity * 0.02:  # 0-2% chance per eccentricity point
		return true

	# Continuous reactivity - higher reactivity = more likely to change
	if consecutive_goals_against > 0:
		# Base chance increases with consecutive goals and reactivity
		var base_chance = (consecutive_goals_against * 0.2) * reactivity
		
		# Defense flexibility modifies the chance
		var final_chance = base_chance * defense_flexibility
		
		# Add small random element
		final_chance += randf() * 0.1
		
		return randf() < final_chance
	
	return false

func get_next_defense() -> String:
	if current_defense == defense_1:
		return defense_2
	else:
		return defense_1

func check_substitution_plans(myTeam: Team, pitchCount: int) -> Array:
	var substitutions = []
	for i in range(p_plan_time.size()):
		if pitchCount == p_plan_time[i]:
			var plan_player_type = p_plan_players[i]
			var replacement = find_best_replacement_by_type(myTeam, "P", plan_player_type)
			if replacement and replacement != myTeam.P:
				substitutions.append({"position": "P", "player_out": myTeam.P, "player_in": replacement})
	
	return substitutions

func check_need_substitution(myTeam: Team, otherTeam: Team, myScore: int, otherScore: int, pitchCount: int, pitches_remaining: int) -> Array:
	var substitutions = []
	
	if pitchCount < GlobalSettings.pitch_limit/2:#early game, try to keep the starters in
		var sub_chance = reactivity * 0.3 #more reactive managers are more likely to sub early
		# Check for injuries first
		var injury_subs = check_injury_substitutions(myTeam)
		if injury_subs:
			substitutions.append_array(injury_subs)
		# Check for severe mismatches
		var p_mismatch = get_p_mismatch(myTeam, otherTeam)
		# Use reactivity and severity to weigh chance
		var mismatch_severity = abs(p_mismatch)
		var mismatch_chance = mismatch_severity * reactivity * matchups
		if mismatch_chance > randf() and substitutions.size() == 0:
			var position_subs = address_mismatch(myTeam, otherTeam, p_mismatch)
			if position_subs:
				substitutions.append_array(position_subs)
	else: #late game, more likely to substitute
		var sub_chance = reactivity * 0.7
		var fatigue_subs = check_fatigue_substitutions(myTeam, pitchCount)
		if fatigue_subs:
			substitutions.append_array(fatigue_subs)
		if substitutions.size() == 0 and randf() < sub_frequency_f:
			var forward_subs = check_forward_substitutions(myTeam, pitchCount)
			if forward_subs:
				substitutions.append_array(forward_subs)
		var strategic_subs = check_strategic_substitutions(myTeam, myScore, otherScore, pitches_remaining)
		if strategic_subs:
			substitutions.append_array(strategic_subs)
	return substitutions

func check_forward_substitutions(myTeam: Team, pitchCount: int) -> Array:
	var substitutions = []
	var lf_substitute = find_best_forward_substitute(myTeam, "LF", myTeam.LF)
	if lf_substitute and myTeam.subs_remaining > 0:
		substitutions.append({"position": "LF", "player_out": myTeam.LF, "player_in": lf_substitute})
	if substitutions.size() == 0 or mix_f_roles:
		var rf_substitute = find_best_forward_substitute(myTeam, "RF", myTeam.RF)
		if rf_substitute and myTeam.subs_remaining > substitutions.size():
			substitutions.append({"position": "RF", "player_out": myTeam.RF, "player_in": rf_substitute})
	return substitutions

func check_injury_substitutions(myTeam: Team) -> Array:
	var substitutions = []
	
	for player in myTeam.onfield_players:
		var performance_drop = calculate_performance_drop(player)
		
		# Weighted decision based on injury tolerance
		# Lower tolerance = more likely to sub for same performance drop
		var sub_probability = performance_drop * (1.0 - injury_tolerance)
		
		# Add small random factor
		sub_probability += randf() * 0.1
		
		if randf() < sub_probability:
			var replacement = find_best_replacement(myTeam, player.position_type)
			if replacement and replacement != player:
				substitutions.append({"position": player.position_type, "player_out": player, "player_in": replacement})
	
	return substitutions

func calculate_performance_drop(player: Player) -> float:
	# Calculate base overall without any buffs
	var base_overall = calculate_base_overall(player)
	
	# Calculate current overall with all buffs
	var current_overall = calculate_current_overall(player)
	
	# Performance drop (0-1 scale)
	var performance_drop = 0.0
	if base_overall > 0:
		performance_drop = 1.0 - (current_overall / base_overall)
	
	return clamp(performance_drop, 0.0, 1.0)

func calculate_base_overall(player: Player) -> float:
	# Store current buffs
	var original_buffs = player.active_buffs.duplicate(true)
	
	# Remove all buffs temporarily
	for buff_name in original_buffs:
		player.remove_buff(buff_name)
	
	# Calculate base overall
	var base_overall = 0.0
	match player.position_type:
		"pitcher":
			base_overall = player.calculate_pitcher_overall()
		"forward":
			base_overall = player.calculate_forward_overall()
		"guard":
			base_overall = player.calculate_guard_overall()
		"keeper":
			base_overall = player.calculate_keeper_overall()
	
	# Restore buffs
	for buff_name in original_buffs:
		var buff_data = original_buffs[buff_name]
		player.add_buff(buff_name, buff_data["attributes"], buff_data["values"])
	
	return base_overall

func calculate_current_overall(player: Player) -> float:
	# Calculate with all current buffs applied
	var current_overall = 0.0
	match player.position_type:
		"pitcher":
			current_overall = player.calculate_pitcher_overall()
		"forward":
			current_overall = player.calculate_forward_overall()
		"guard":
			current_overall = player.calculate_guard_overall()
		"keeper":
			current_overall = player.calculate_keeper_overall()
	
	return current_overall

func check_fatigue_substitutions(myTeam: Team, pitchCount: int) -> Array:
	var substitutions = []
	# Factor in injuries to energy calculation
	for player in myTeam.onfield_players:
		var fatigue_threshold = endurance_sub
		var position_frequency = get_position_sub_frequency(player.position_type)
		fatigue_threshold *= position_frequency
		
		# Factor in injuries - injured players have effectively less energy
		var health_factor = player.status.health / 100.0
		var effective_energy = player.status.energy * health_factor
		
		if effective_energy < fatigue_threshold * 100: # Energy is 0-100
			var replacement = find_best_replacement(myTeam, player.position_type)
			if replacement and replacement != player:
				substitutions.append({"position": player.position_type, "player_out": player, "player_in": replacement})
	return substitutions

func check_strategic_substitutions(myTeam: Team, myScore: int, otherScore: int, pitches_remaining: int) -> Array:
	var substitutions = []
	# If we're losing and need offense, look for offensive upgrades
	if myScore < otherScore and pitches_remaining < GlobalSettings.pitch_limit * 0.3:
		var offensive_roles = ["Shooting Forward", "Attacking Forward", "Rusher", "Rebounder", "Pick and Roller", "Pick and Popper", "Target Forward"]
		
		# Check LF for offensive upgrade
		var current_lf_offense = get_weighted_forward_role_score(
			myTeam.LF, offensive_roles, [0.5, 0.3, 0.2]  # Weight shooter most heavily for offense
		)
		var best_lf_offense = find_offensive_forward_upgrade(myTeam, "LF", offensive_roles)
		
		if best_lf_offense and best_lf_offense != myTeam.LF:
			var bench_offense = get_weighted_forward_role_score(
				best_lf_offense, offensive_roles, [0.5, 0.3, 0.2]
			)
			# Factor in eccentricity - more eccentric coaches have lower thresholds
			var improvement_threshold = 1.15 - (eccentricity * 0.1)  # 1.05 to 1.15
			if bench_offense > current_lf_offense * improvement_threshold:
				substitutions.append({"position": "LF", "player_out": myTeam.LF, "player_in": best_lf_offense})
	
	#if we're winning and need defense, look for defensive upgrades
	elif myScore > otherScore and pitches_remaining < GlobalSettings.pitch_limit * 0.4:
		var defensive_roles = ["Defensive Forward", "Support Forward", "Target Forward", "Roving Menace"]
		var defensive_sub = find_defensive_forward_upgrade(myTeam, defensive_roles)
		if defensive_sub:
			substitutions.append(defensive_sub)
	return substitutions

func get_p_mismatch(myTeam: Team, otherTeam: Team) -> float:
	#positive values mean their pitcher is better/tougher, negative values mean our pitcher is better/tougher
	var better = get_p_better(myTeam, otherTeam)
	var tougher = get_p_tougher(myTeam, otherTeam)
	var mismatch = (better + tougher) / 4.0 # Normalize to -1 to 1 range
	# Weight violence preference continuously
	if tougher > 0: #their pitcher is tougher
		mismatch += (tougher / 4.0) * violence * 0.5  # Scale violence effect
	return clamp(mismatch, -1.0, 1.0)

func address_mismatch(myTeam: Team, otherTeam: Team, mismatch: float) -> Array:
	var substitutions = []
	
	# Use reactivity and severity to determine substitution urgency
	var severity = abs(mismatch)
	var substitution_urgency = severity * reactivity
	
	if mismatch > 0.7 and randf() < substitution_urgency: #their pitcher is much better/tougher
		var tougher_pitcher = find_toughest_pitcher(myTeam)
		if tougher_pitcher and tougher_pitcher != myTeam.P:
			substitutions.append({"position": "P", "player_out": myTeam.P, "player_in": tougher_pitcher})
	return substitutions

func is_losing_badly(myScore: int, otherScore: int, pitches_remaining: int) -> bool:
	var score_diff = otherScore - myScore
	
	# If winning or tied, not losing badly
	if score_diff <= 0:
		return false
	
	# Calculate maximum possible comeback based on pitches remaining
	var max_possible_comeback = 0
	
	if GlobalSettings.regular_season:
		# In regular season, can tie with current pitches + potentially 1 OT pitch
		max_possible_comeback = pitches_remaining + 1
	else:
		# In playoffs, need to win by 2, so need more goals
		max_possible_comeback = pitches_remaining  # Conservative estimate
	
	# Calculate deficit severity (0-1 scale)
	var deficit_severity = 0.0
	if max_possible_comeback > 0:
		deficit_severity = clamp(float(score_diff) / float(max_possible_comeback), 0.0, 2.0)
	else:
		deficit_severity = 2.0  # No pitches left, any deficit is severe
	
	# Factor in game progress - earlier deficits are less severe
	var game_progress = 1.0 - (float(pitches_remaining) / GlobalSettings.pitch_limit)
	var time_factor = 1.0 - (game_progress * 0.3)  # Slightly more severe early
	
	# Combined severity
	var overall_severity = deficit_severity * time_factor
	
	# Violence threshold decreases as violence rating increases
	# High violence coaches will resort to violence with smaller deficits
	var violence_threshold = 0.8 - (violence * 0.6)  # 0.2 to 0.8 threshold
	
	return overall_severity > violence_threshold

func make_violence_subs(myTeam: Team) -> Array:
	var substitutions = []
	
	# Calculate violence urgency based on score and violence rating
	var violence_urgency = violence * 0.8  # Base urgency
	
	# Find players with high violence ratings
	var violent_players = []
	for bench_player in myTeam.next_bench:
		if bench_player.position_type == "forward":
			var violence_rating = get_player_violence_rating(bench_player)
			violent_players.append({"player": bench_player, "rating": violence_rating})
	
	violent_players.sort_custom(func(a, b): return a["rating"] > b["rating"])
	
	var current_lf_violence = get_player_violence_rating(myTeam.LF)
	var current_rf_violence = get_player_violence_rating(myTeam.RF)
	
	# Violence threshold decreases with higher violence rating
	var violence_threshold = 15 - (violence * 10)  # 5 to 15 threshold
	
	for violent_data in violent_players:
		var violent_player = violent_data["player"]
		var violence_rating = violent_data["rating"]
		
		if substitutions.size() == 0 and violence_rating > current_lf_violence + violence_threshold:
			substitutions.append({"position": "LF", "player_out": myTeam.LF, "player_in": violent_player})
		elif substitutions.size() == 1 and violence_rating > current_rf_violence + violence_threshold:
			substitutions.append({"position": "RF", "player_out": myTeam.RF, "player_in": violent_player})
	
	return substitutions

func get_player_violence_rating(player: Player) -> float:
	# Skull crackers are best, support and anti_keeper are okay, scorers are worst
	var skull_cracker_rating = rate_player_for_player_type(player, "skull_cracker")
	var support_rating = rate_player_for_player_type(player, "support")
	var anti_keeper_rating = rate_player_for_player_type(player, "anti_keeper")
	var scorer_rating = rate_player_for_player_type(player, "scorer")
	
	# Weighted average favoring skull_cracker
	return (skull_cracker_rating * 0.6 + support_rating * 0.2 + 
			anti_keeper_rating * 0.15 + scorer_rating * 0.05)

func adjust_forward_roles_on_subs(myTeam: Team, substitutions: Array) -> Dictionary:
	var role_changes = {}
	var forward_substituted = false
	
	# Check if any forwards were substituted
	for sub in substitutions:
		if sub["position"] == "LF" or sub["position"] == "RF":
			forward_substituted = true
			break
	
	if forward_substituted:
		if !mix_f_roles:
			# Weight-based decision for both forwards
			var lf_change_weight = calculate_role_change_weight(myTeam.LF, current_lf_role)
			var rf_change_weight = calculate_role_change_weight(myTeam.RF, current_rf_role)
			
			# Flexibility affects the threshold for change
			var flexibility_threshold = 0.5 - (flexibility * 0.3)  # 0.2 to 0.5
			
			if randf() < lf_change_weight * flexibility:
				var new_role = get_best_tactical_role_for_player(myTeam.LF)
				role_changes["LF"] = new_role
				current_lf_role = new_role
			
			if randf() < rf_change_weight * flexibility:
				var new_role = get_best_tactical_role_for_player(myTeam.RF)
				role_changes["RF"] = new_role
				current_rf_role = new_role
		else:
			# Only update substituted players with weighted decision
			for sub in substitutions:
				if sub["position"] == "LF":
					var change_weight = calculate_role_change_weight(myTeam.LF, current_lf_role)
					if randf() < change_weight * flexibility:
						var new_role = get_best_tactical_role_for_player(myTeam.LF)
						role_changes["LF"] = new_role
						current_lf_role = new_role
				elif sub["position"] == "RF":
					var change_weight = calculate_role_change_weight(myTeam.RF, current_rf_role)
					if randf() < change_weight * flexibility:
						var new_role = get_best_tactical_role_for_player(myTeam.RF)
						role_changes["RF"] = new_role
						current_rf_role = new_role
	
	return role_changes

func calculate_role_change_weight(player: Player, current_role: String) -> float:
	var best_role = get_best_tactical_role_for_player(player)
	var best_score = rate_player_for_forward_role(player, best_role)
	var current_score = rate_player_for_forward_role(player, current_role)
	
	if best_score <= current_score:
		return 0.0
	
	# Calculate improvement percentage
	var improvement = (best_score - current_score) / current_score
	
	# Convert to weight (0-1 scale)
	return clamp(improvement * 2.0, 0.0, 1.0)  # Cap at 100% improvement = 1.0 weight

func get_best_tactical_role_for_player(player: Player) -> String:
	var best_role = "Classic Forward"  # Default
	var best_score = -1.0
	
	for role in forward_role_preferences.keys():
		var score = rate_player_for_forward_role(player, role)
		if score > best_score:
			best_score = score
			best_role = role
	
	return best_role

func get_p_better(myTeam: Team, otherTeam: Team) -> int:
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

func get_p_tougher(myTeam: Team, otherTeam: Team) -> int:
	if otherTeam.P.attributes.toughness - myTeam.P.attributes.toughness > 10: #their guy is tougher
		return 2
	elif otherTeam.P.attributes.toughness - myTeam.P.attributes.toughness > 5:
		return 1
	elif myTeam.P.attributes.toughness - otherTeam.P.attributes.toughness > 10:
		return -2
	elif myTeam.P.attributes.toughness - otherTeam.P.attributes.toughness > 5:
		return -1
	else:
		return 0

# Calculate a player's suitability for a specific forward role
func rate_player_for_forward_role(player: Player, role: String) -> float:
	if not forward_role_preferences.has(role):
		return 0.0
	
	var preferences = forward_role_preferences[role]
	var total_score = 0.0
	
	# Get player's ratings for each player type
	var scorer_rating = rate_player_for_player_type(player, "scorer")
	var anti_keeper_rating = rate_player_for_player_type(player, "anti_keeper")
	var support_rating = rate_player_for_player_type(player, "support")
	var skull_cracker_rating = rate_player_for_player_type(player, "skull_cracker")
	
	# Apply role preferences
	total_score += scorer_rating * preferences["scorer"]
	total_score += anti_keeper_rating * preferences["anti_keeper"]
	total_score += support_rating * preferences["support"]
	total_score += skull_cracker_rating * preferences["skull_cracker"]
	
	return total_score

# Calculate a player's rating for a specific player type (inherent to player)
func rate_player_for_player_type(player: Player, player_type: String) -> float:
	var att = player.attributes
	match player_type:
		"scorer":
			return (att.shooting * 3 + att.accuracy * 3 + att.positioning + 
				   att.speedRating + att.reactions + att.agility + att.endurance) / 11.0
		"anti_keeper":
			return (att.power * 3 + att.speedRating * 3 + att.balance + 
				   att.endurance + att.durability) / 9.0
		"support":
			return (att.power + att.accuracy + att.positioning + 
				   att.balance + att.reactions + att.durability) / 6.0
		"skull_cracker":
			# Incorporate player's brawling tendencies
			var base_rating = (att.power + att.balance + att.durability + 
					   att.toughness * 2 + att.shooting) / 7.0
			# Factor in brawl preferences - players who join fights get better rating
			var brawl_aggressiveness = (player.brawl_preferences.join + player.brawl_preferences.partner) / 2.0
			var brawl_avoidance = player.brawl_preferences.cower
			var brawl_factor = 0.5 + (brawl_aggressiveness * 0.5) - (brawl_avoidance * 0.5)
			return base_rating * clamp(brawl_factor, 0.5, 1.5)
		_:
			return 0.0

func find_best_forward_substitute(myTeam: Team, position: String, current_player: Player) -> Player:
	var best_substitute = null
	var best_weighted_score = -1.0
	
	var roles = []
	var weights = []
	
	if position == "LF":
		roles = [lf_role_1, lf_role_2, lf_role_3]
		weights = [0.5 - (flexibility * 0.2), 0.35, 0.15 + (flexibility * 0.2)]  # More flexible coaches weight role 3 higher
	else: # RF
		roles = [rf_role_1, rf_role_2, rf_role_3]
		weights = [0.5 - (flexibility * 0.2), 0.35, 0.15 + (flexibility * 0.2)]
	
	# Factor in energy for current player's score
	var current_energy_factor = current_player.status.energy / 100.0
	var current_score = get_weighted_forward_role_score(current_player, roles, weights) * current_energy_factor
	
	for bench_player in myTeam.next_bench:
		if bench_player.position_type != "forward":
			continue
			
		# Check if this player can actually play the position
		if not bench_player.can_play_position(position):
			continue
			
		# Factor in energy for bench player's score
		var bench_energy_factor = bench_player.status.energy / 100.0
		var bench_score = get_weighted_forward_role_score(bench_player, roles, weights) * bench_energy_factor
		
		# Calculate substitution value with weighted factors
		var energy_factor = 1.0
		if current_player.status.energy < 50:
			energy_factor = 1.5  # More likely to sub tired players
		
		var eccentricity_factor = 1.0 + (eccentricity * 0.3)  # Eccentric coaches more likely to sub
		
		var substitution_value = (bench_score * energy_factor * eccentricity_factor) - current_score
		
		# Only consider if positive value, with some randomness
		if substitution_value > 0:
			var substitution_weight = substitution_value * 0.1  # Convert to probability weight
			substitution_weight += randf() * 0.1  # Small random factor
			
			if substitution_weight > best_weighted_score:
				best_weighted_score = substitution_weight
				best_substitute = bench_player
	
	# Only substitute if weight exceeds threshold
	if best_substitute and best_weighted_score > 0.1:  # Minimum 10% improvement threshold
		return best_substitute
	
	return null

func get_weighted_forward_role_score(player: Player, roles: Array, weights: Array) -> float:
	var total_score = 0.0
	for i in range(roles.size()):
		var role_score = rate_player_for_forward_role(player, roles[i])
		total_score += role_score * weights[i]
	return total_score

func find_offensive_forward_upgrade(myTeam: Team, position: String, offensive_roles: Array) -> Player:
	var best_player = null
	var best_score = -1.0
	var current_player = myTeam.LF if position == "LF" else myTeam.RF
	
	# Factor in energy for current player
	var current_energy_factor = current_player.status.energy / 100.0
	var current_score = get_weighted_forward_role_score(current_player, offensive_roles, [0.5, 0.3, 0.2]) * current_energy_factor
	
	for bench_player in myTeam.next_bench:
		if bench_player.position_type != "forward":
			continue
			
		if not bench_player.can_play_position(position):
			continue
		
		# Factor in energy for bench player
		var bench_energy_factor = bench_player.status.energy / 100.0
		var bench_score = get_weighted_forward_role_score(bench_player, offensive_roles, [0.5, 0.3, 0.2]) * bench_energy_factor
		
		# Factor in eccentricity - more eccentric coaches have lower thresholds
		var improvement_threshold = 1.15 - (eccentricity * 0.1)  # 1.05 to 1.15
		
		if bench_score > current_score * improvement_threshold:
			if bench_score > best_score:
				best_score = bench_score
				best_player = bench_player
	
	return best_player

func find_defensive_forward_upgrade(myTeam: Team, defensive_roles: Array) -> Dictionary:
	var best_sub = null
	var best_improvement = 0.0
	
	# Check both forward positions
	for position in ["LF", "RF"]:
		var current_player = myTeam.LF if position == "LF" else myTeam.RF
		
		# Factor in energy for current player
		var current_energy_factor = current_player.status.energy / 100.0
		var current_score = get_weighted_forward_role_score(current_player, defensive_roles, [0.4, 0.4, 0.2]) * current_energy_factor
		
		for bench_player in myTeam.next_bench:
			if bench_player.position_type != "forward":
				continue
				
			if not bench_player.can_play_position(position):
				continue
			
			# Factor in energy for bench player
			var bench_energy_factor = bench_player.status.energy / 100.0
			var bench_score = get_weighted_forward_role_score(bench_player, defensive_roles, [0.4, 0.4, 0.2]) * bench_energy_factor
			
			var improvement = bench_score - current_score
			
			# Factor in eccentricity - more eccentric coaches have lower thresholds
			var improvement_threshold = 10 - (eccentricity * 5)  # 5 to 10
			
			if improvement > best_improvement and improvement > improvement_threshold:
				best_improvement = improvement
				best_sub = {
					"position": position, 
					"player_out": current_player, 
					"player_in": bench_player
				}
	
	return best_sub

func find_forward_sub(myTeam: Team, otherTeam: Team) -> Player:
	var game_weight = calculate_game_weight(myTeam, otherTeam)
	var best_player = null
	var best_score = -1.0
	
	for player in myTeam.next_bench:
		if player.position_type != "forward":
			continue
			
		var role_score = rate_player_for_forward_role(player, current_lf_role)
		var overall = player.calculate_forward_overall()
		var score = (role_score * 0.6) + (overall * 0.4) * game_weight
		
		if score > best_score:
			best_score = score
			best_player = player
	
	return best_player

func calculate_game_weight(myTeam: Team, otherTeam: Team) -> float:
	#TODO: set game state
	var game_percentage #pitches played/max pitches
	var scoreDiff #difference in team score
	var comeback_possible #if there are enough pithces left in the game to overcome the score diff, factoring in overtime
	var is_sudden_death #no reason to save substitutions if it's regular season overtime, but for playoff overtime which can last longer, better to hold off
	#TODO: calculate weights
	return 1.0

func find_best_replacement(myTeam: Team, position: String) -> Player:
	var best_player = null
	var best_rating = -1.0
	
	for player in myTeam.next_bench:
		if player.position_type != position:
			continue
			
		var rating = 0.0
		match position:
			"pitcher":
				rating = player.calculate_pitcher_overall()
			"forward":
				rating = player.calculate_forward_overall()
			"guard":
				rating = player.calculate_guard_overall()
			"keeper":
				rating = player.calculate_keeper_overall()
		
		if rating > best_rating:
			best_rating = rating
			best_player = player
	
	return best_player

func find_best_replacement_by_type(myTeam: Team, position: String, player_type: String) -> Player:
	var best_player = null
	var best_score = -1.0
	
	for player in myTeam.next_bench:
		if player.position_type != position:
			continue
		
		var type_match_score = calculate_type_match_score(player, player_type)
		if type_match_score > best_score:
			best_score = type_match_score
			best_player = player
	
	return best_player

func calculate_type_match_score(player: Player, player_type: String) -> float:
	var score = 0.0
	var att = player.attributes
	
	match player_type:
		"Workhorse":
			score = (att.endurance * 0.5 + att.durability * 0.3 + att.focus * 0.2) / 100.0
		"Enforcer":
			score = (att.toughness * 0.4 + att.power * 0.3 + att.aggression * 0.3) / 100.0
		"Curveball":
			score = (att.focus * 0.4 + att.accuracy * 0.4 + att.confidence * 0.2) / 100.0
		"Fastball":
			score = (att.throwing * 0.4 + att.power * 0.4 + att.accuracy * 0.2) / 100.0
		"Goal Scorer":
			score = (att.shooting * 0.4 + att.accuracy * 0.3 + att.positioning * 0.3) / 100.0
		"Anti-Keeper":
			score = (att.power * 0.5 + att.speedRating * 0.3 + att.balance * 0.2) / 100.0
		"Support Forward":
			score = (att.positioning * 0.4 + att.reactions * 0.3 + att.accuracy * 0.3) / 100.0
		"Skull Cracker":
			score = (att.toughness * 0.4 + att.power * 0.3 + att.aggression * 0.3) / 100.0
		"Ball Hound":
			score = (att.reactions * 0.4 + att.blocking * 0.3 + att.speedRating * 0.3) / 100.0
		"Defender":
			score = (att.positioning * 0.4 + att.blocking * 0.3 + att.power * 0.3) / 100.0
		"Bully":
			score = (att.power * 0.4 + att.toughness * 0.4 + att.aggression * 0.2) / 100.0
		_:
			# Default case - likely a goalkeeper or undefined type
			# Use goalkeeper-specific attributes
			score = (att.reactions * 0.35 + att.blocking * 0.35 + att.agility * 0.2 + att.positioning * 0.1) / 100.0
	
	return score

func find_toughest_pitcher(myTeam: Team) -> Player:
	var toughest = null
	var max_toughness = -1
	
	for player in myTeam.next_bench:
		if player.position_type == "pitcher" and player.attributes.toughness > max_toughness:
			max_toughness = player.attributes.toughness
			toughest = player
	
	return toughest

func find_toughest_player_by_position(myTeam: Team, position_type: String) -> Player:
	var toughest = null
	var max_toughness = -1
	
	for player in myTeam.next_bench:
		if player.position_type == position_type and player.attributes.toughness > max_toughness:
			max_toughness = player.attributes.toughness
			toughest = player
	
	return toughest

func get_position_sub_frequency(position_type: String) -> float:
	match position_type:
		"pitcher":
			return sub_frequency_p
		"forward":
			return sub_frequency_f
		"guard":
			return sub_frequency_g
		"keeper":
			return sub_frequency_k
		_:
			return 0.5

func note_goal_against(pitchCount: int):
	consecutive_goals_against += 1
	last_goal_pitch = pitchCount
