class_name Playbook
extends Resource

@export_group("Play Collections")
@export var offense_plays: Array[OffensePlay] = []
@export var defense_plays: Array[DefensePlay] = []
@export var air_hockey_plays: Array[AirHockeyPlay] = []

@export_group("Play Limits")
@export_range(1, 25) var max_offense_plays: int = 15
@export_range(1, 20) var max_defense_plays: int = 10
@export_range(1, 5) var max_air_hockey_plays: int = 3

func _validate_play_counts():
	# Ensure we don't exceed maximum allowed plays
	if offense_plays.size() > max_offense_plays:
		offense_plays = offense_plays.slice(0, max_offense_plays)
	if defense_plays.size() > max_defense_plays:
		defense_plays = defense_plays.slice(0, max_defense_plays)
	if air_hockey_plays.size() > max_air_hockey_plays:
		air_hockey_plays = air_hockey_plays.slice(0, max_air_hockey_plays)

func add_offense_play(play: OffensePlay) -> bool:
	if offense_plays.size() >= max_offense_plays:
		return false
	offense_plays.append(play)
	return true

func add_defense_play(play: DefensePlay) -> bool:
	if defense_plays.size() >= max_defense_plays:
		return false
	defense_plays.append(play)
	return true

func add_air_hockey_play(play: AirHockeyPlay) -> bool:
	if air_hockey_plays.size() >= max_air_hockey_plays:
		return false
	air_hockey_plays.append(play)
	return true

func get_random_offense_play() -> OffensePlay:
	if offense_plays.is_empty():
		push_warning("No offense plays in playbook!")
		return null
	return offense_plays.pick_random()

func get_random_defense_play() -> DefensePlay:
	if defense_plays.is_empty():
		push_warning("No defense plays in playbook!")
		return null
	return defense_plays.pick_random()

func get_random_air_hockey_play() -> AirHockeyPlay:
	if air_hockey_plays.is_empty():
		push_warning("No air hockey plays in playbook!")
		return null
	return air_hockey_plays.pick_random()
