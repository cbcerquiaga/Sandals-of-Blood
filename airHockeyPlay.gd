class_name AirHockeyPlay
extends Resource

@export_group("Goalie Behavior Weights")
@export_range(0.0, 1.0) var defensive_weight: float = 0.5
@export_range(0.0, 1.0) var aggressive_weight: float = 0.3
@export_range(0.0, 1.0) var violent_weight: float = 0.2

@export_group("Forward Behavior Weights") 
@export_range(0.0, 1.0) var attack_goalie_weight: float = 0.25
@export_range(0.0, 1.0) var protect_goalie_weight: float = 0.15
@export_range(0.0, 1.0) var defend_high_weight: float = 0.2
@export_range(0.0, 1.0) var defend_low_weight: float = 0.2
@export_range(0.0, 1.0) var get_open_weight: float = 0.1
@export_range(0.0, 1.0) var chase_ball_weight: float = 0.1

@export_group("Situation Modifiers")
@export var winning_modifier: float = 1.2
@export var losing_modifier: float = 0.8
@export var neutral_modifier: float = 1.0

func get_goalie_behavior_weights(score_difference: int) -> Dictionary:
	var modifier = _get_situation_modifier(score_difference)
	return {
		"defensive": defensive_weight * modifier,
		"aggressive": aggressive_weight * modifier,
		"violent": violent_weight * modifier
	}

func get_forward_behavior_weights(score_difference: int) -> Dictionary:
	var modifier = _get_situation_modifier(score_difference)
	return {
		"attack_goalie": attack_goalie_weight * modifier,
		"protect_goalie": protect_goalie_weight * modifier,
		"defend_high": defend_high_weight * modifier,
		"defend_low": defend_low_weight * modifier,
		"get_open": get_open_weight,
		"chase_ball": chase_ball_weight
	}

func _get_situation_modifier(score_difference: int) -> float:
	if score_difference > 1:
		return winning_modifier
	elif score_difference < -1:
		return losing_modifier
	return neutral_modifier

func normalize_weights(weights: Dictionary) -> Dictionary:
	var total = 0.0
	for weight in weights.values():
		total += weight
	
	var normalized = {}
	for key in weights:
		normalized[key] = weights[key] / total if total > 0 else 0.0
	
	return normalized

func get_recommended_goalie_behavior(score_difference: int) -> String:
	var weights = get_goalie_behavior_weights(score_difference)
	var max_weight = -INF
	var recommended = "defensive"
	
	for behavior in weights:
		if weights[behavior] > max_weight:
			max_weight = weights[behavior]
			recommended = behavior
	
	return recommended

func get_recommended_forward_behavior(score_difference: int) -> String:
	var weights = get_forward_behavior_weights(score_difference)
	var max_weight = -INF
	var recommended = "chase_ball"
	
	for behavior in weights:
		if weights[behavior] > max_weight:
			max_weight = weights[behavior]
			recommended = behavior
	
	return recommended

func debug_print_weights(score_difference: int):
	print("-- Current Play Strategy --")
	print("Score Difference: ", score_difference)
	print("Goalie Weights: ", normalize_weights(get_goalie_behavior_weights(score_difference)))
	print("Forward Weights: ", normalize_weights(get_forward_behavior_weights(score_difference)))
	print("Recommended Goalie: ", get_recommended_goalie_behavior(score_difference))
	print("Recommended Forward: ", get_recommended_forward_behavior(score_difference))
