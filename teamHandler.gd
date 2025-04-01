class_name TeamHandler
extends Node

signal offense_state_changed(is_on_offense: bool)
signal score_changed(new_score: int)
signal substitute_used(player: BallPlayer, substitute: Dictionary)

@export_group("Team Settings")
@export var starting_offense: bool = false
@export var starting_score: int = 0
@export var max_substitutes: int = 5

var pitcher
var catcher
var goalie
var left_safety
var right_safety
var batter
var left_flanker
var right_flanker
var forward


var is_on_offense: bool = false
var score: int = 0
var substitutes: Array[Dictionary] = []  # Stores {role: String, stats: Dictionary}
var active_players: Dictionary = {}      # role: BallPlayer
var allPlayers: Array[BallPlayer]

func _ready():
	forward = $Ironman/Forward
	right_flanker = $Ironman/Right_Flanker
	left_flanker = $Ironman/Left_Flanker
	batter = $Defense/Batter
	left_safety = $"Defense/Left Safety"
	right_safety = $"Defense/Right Safety"
	pitcher = $Offense/Pitcher
	catcher = $Offense/Catcher
	goalie = $Offense/Goalie


func set_offense():
	var offensePlayers = [forward, left_flanker, right_flanker, pitcher, catcher, goalie]
	for player in allPlayers:
		if offensePlayers.has(player):
			player.process_mode = 0#turn on
			player.show()#turn on
		else:
			player.process_mode = 4#turn off
			player.hide()
	
func set_defense():
	var defensePlayers = [forward, left_flanker, right_flanker, batter, left_safety, right_safety]
	for player in allPlayers:
		if defensePlayers.has(player):
			player.process_mode = 0#turn on
			player.show()#turn on
		else:
			player.process_mode = 4#turn off
			player.hide()
			
func _update_team_visibility():
	# Toggle core players
	_set_player_active("pitcher", is_on_offense)
	_set_player_active("catcher", is_on_offense)
	_set_player_active("goalie", is_on_offense)
	_set_player_active("left_safety", not is_on_offense)
	_set_player_active("right_safety", not is_on_offense)
	_set_player_active("batter", not is_on_offense)
	
	# Always active players
	_set_player_active("forward", true)
	_set_player_active("left_flanker", true)
	_set_player_active("right_flanker", true)

func _set_player_active(role: String, active: bool):
	if active_players.has(role):
		var player = active_players[role]
		player.visible = active
		player.set_process(active)
		player.set_physics_process(active)
		player.set_process_input(active)

func add_score(points: int):
	score += points
	score_changed.emit(score)

func reset_score():
	score = 0
	score_changed.emit(score)

func get_active_players() -> Array[BallPlayer]:
	return active_players.values().filter(func(p): return p.visible)

func use_substitute(role: String, sub_index: int) -> bool:
	if sub_index < 0 or sub_index >= substitutes.size():
		return false
	
	var sub = substitutes[sub_index]
	if sub["role"] != role and sub["role"] != "flanker" and sub["role"] != "safety":
		return false
	
	if active_players.has(role):
		var player = active_players[role]
		
		# Apply substitute stats (example - modify as needed)
		player.movement_speed = sub["stats"]["speed"]
		#if player is Batter: TODO: bug fix
		#	player.swing_power *= sub["stats"]["power"]
		
		substitutes.remove_at(sub_index)
		substitute_used.emit(player, sub)
		return true
	
	return false

#TODO
#func get_available_substitutes(role: String) -> Array[Dictionary]:
	#return substitutes.filter(
		#func(sub): 
			#return sub["role"] == role or 
				  #(role in ["left_flanker", "right_flanker"] and sub["role"] == "flanker") or
				  #(role in ["left_safety", "right_safety"] and sub["role"] == "safety")
	#)

func get_player(role: String) -> BallPlayer:
	return active_players.get(role)
