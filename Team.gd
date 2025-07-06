class_name Team
extends Node

# Team Configuration
var team_id: int
var is_on_offense: bool #whether or not the team is pitching
var is_player_team: bool#whether ot not the team is human controlled
var roster: Array[Player] = []
var bench: Array[Player] = []  # Players not currently in positions
var buffs: Array[Dictionary] = []
var strategy: Dictionary = {
	"base_aggression": 1.0,  # Multiplier for all positions
	"position_aggression": {
		"keeper": 1.0,
		"guard": 1.0,
		"forward": 1.0,
		"pitcher": 1.0
	},
	"substitution": {
		"energy_threshold": 30.0,  # % energy remaining
		"injury_threshold": 3,     # number of injuries
		"priority": ["pitcher", "keeper", "forward", "guard"]  # Substitution order
	},
	"brawling": {
		"max_in": 3,
		"urgency": 0.7,  # 0-1 (1 = immediate)
		"attack_tendency": 0.6,
		"block_tendency": 0.3
	},
	"tactics" : {
		"LF": "Classic Forward",
		"RF": "Rusher",
		"D": "Positional Man to Man"
	}
}

@export var K: Player
@export var P: Player
@export var LG: Player
@export var RG: Player
@export var LF: Player
@export var RF: Player

@onready var onfield_players = [K, P, LG, RG, LF, RF]

# Current Field Positions
var positions: Dictionary = {
	"keeper": null,
	"guard_l": null,
	"guard_r": null,
	"forward_l": null,
	"forward_r": null,
	"pitcher": null
}

var has_readied

signal on_team_ready(id: int)

func _init():
	has_readied = false
	K = Keeper.new()
	P = Reworked_Pitcher.new()
	LG = Guard.new()
	RG = Guard.new()
	LF = Forward.new()
	RF = Forward.new()
	add_players_to_roster()
	initialize_default_strategy()
	
func _process(delta: float) -> void:
	if !has_readied:
		#print("not ready")
		if K.attributes.power != null && LF.attributes.power != null:
			has_readied = true
			on_team_ready.emit(team_id)
			print("ready")

func initialize_default_strategy():
	# Set default position aggression modifiers
	strategy.position_aggression = {
		"keeper": 0.6,
		"guard": 1.2,
		"forward": 1.5,
		"pitcher": 0.3
	}
	#TODO: set the team_strategy dictionary for each player

func add_players_to_roster():
	add_player(K)
	add_player(P)
	add_player(LG)
	add_player(RG)
	add_player(RF)
	add_player(LF)

func add_player(player: Player):
	roster.append(player)
	bench.append(player)
	player.team = team_id
	apply_team_buffs(player)

func assign_position(position_key: String, player: Player):
	# Clear previous occupant
	if positions[position_key]:
		bench.append(positions[position_key])
	
	# Assign new player
	positions[position_key] = player
	if bench.has(player):
		bench.erase(player)
	
	# Check for out-of-position debuff
	if player.position_type != position_key.trim_suffix("_l").trim_suffix("_r"):
		if not player.has_buff("utility_player"):
			player.add_debuff("out_of_position", {
				"duration": -1,  # Permanent until position change
				"effects": {
					"speed": -1,
					"power": -1,
					"endurance": -1,
					"accuracy": -1,
					"focus": -1,
					"fight": -1,
					"toughness": -1,
					"confidence": -1
				}
			})
	else:
		player.remove_debuff("out_of_position")

func get_position_player(position: String) -> Player:
	return positions.get(position)

func get_all_field_players() -> Array[Player]:
	return positions.values()

func check_substitutions():
	for position_type in strategy.substitution.priority:
		var position_keys = get_position_keys_for_type(position_type)
		for pos_key in position_keys:
			var player = positions[pos_key]
			if needs_substitution(player):
				attempt_substitution(pos_key)

func needs_substitution(player: Player) -> bool:
	if not player:
		return true
		
	return (player.energy < strategy.substitution.energy_threshold or
			player.injury_count >= strategy.substitution.injury_threshold)

func attempt_substitution(position_key: String):
	var position_type = position_key.trim_suffix("_l").trim_suffix("_r")
	
	# Find suitable replacement on bench
	for bench_player in bench:
		if bench_player.position_type == position_type:
			# Found replacement
			assign_position(position_key, bench_player)
			return
	
	# No exact match, try utility players
	for bench_player in bench:
		if bench_player.has_buff("utility_player"):
			assign_position(position_key, bench_player)
			return

func get_position_keys_for_type(position_type: String) -> Array[String]:
	match position_type:
		"keeper":
			return ["keeper"]
		"pitcher":
			return ["pitcher"]
		"guard":
			return ["guard_l", "guard_r"]
		"forward":
			return ["forward_l", "forward_r"]
		_:
			return []

func apply_team_buffs(player: Player):
	for buff in buffs:
		player.add_buff(buff)

func add_team_buff(buff_name: String, modifiers: Dictionary, duration: float = -1):
	buffs.append({
		"name": buff_name,
		"modifiers": modifiers,
		"duration": duration,
		"timer": 0.0 if duration > 0 else -1
	})
	
	# Apply to all players
	for player in roster:
		player.add_buff(buffs[-1])

func remove_team_buff(buff_name: String):
	for i in range(buffs.size() - 1, -1, -1):
		if buffs[i].name == buff_name:
			buffs.remove_at(i)
	
	# Remove from all players
	for player in roster:
		player.remove_debuff(buff_name)

func update_buff_timers(delta: float):
	for i in range(buffs.size() - 1, -1, -1):
		if buffs[i].duration > 0:
			buffs[i].timer += delta
			if buffs[i].timer >= buffs[i].duration:
				remove_team_buff(buffs[i].name)

func get_brawl_decision() -> Dictionary:
	var decision = {
		"join": false,
		"attack": false,
		"block": false
	}
	
	# Base chance to join brawl based on strategy
	if randf() < strategy.brawling.urgency:
		decision.join = true
		
		if randf() < strategy.brawling.attack_tendency:
			decision.attack = true
		elif randf() < strategy.brawling.block_tendency:
			decision.block = true
	
	return decision

func get_modified_aggression(base_aggression: float, position_type: String) -> float:
	var pos_aggression = strategy.position_aggression.get(position_type, 1.0)
	var team_aggression = strategy.base_aggression
	
	# Apply buffs/debuffs
	var aggression_mod = 1.0
	for buff in buffs:
		if buff.modifiers.has("aggression"):
			aggression_mod += buff.modifiers.aggression / 100.0
	
	return base_aggression * pos_aggression * team_aggression * aggression_mod

func should_join_brawl(current_participants: int) -> bool:
	if current_participants >= strategy.brawling.max_in:
		return false
	
	# More likely to join if losing brawl
	var urgency_mod = strategy.brawling.urgency
	if current_participants > 0:
		urgency_mod *= 1.0 + (1.0 - urgency_mod)  # Scale up based on existing participants
	
	return randf() < urgency_mod

func get_brawl_priority_players() -> Array[Player]:
	# Returns players in order they should join brawls
	var priority = []
	
	# Forwards join first, then guards, then keeper last
	priority.append_array([positions.forward_l, positions.forward_r])
	priority.append_array([positions.guard_l, positions.guard_r])
	priority.append(positions.keeper)
	
	# Remove nulls and return
	priority.erase(null)
	return priority

func enlighten(aimTarget, ball, field, keeperWall, ownGoal, oppGoal, oppP, oppK, oppLG, oppRG, oppLF, oppRF, LfWaiting, RfWaiting, LPost, RPost, dHalf, oHalf, rest):
	P.ball = ball
	P.ball_pitched.connect(ball.be_pitched)
	P.special_pitched.connect(ball.be_special_pitched)
	P.oppGoal = oppGoal.global_position
	P.left_wall = field.leftWall
	P.right_wall = field.rightWall
	P.rest_position = rest
	P.opp_pitcher = oppP
	P.running_positions = [field.chaseNE, field.chaseSE, field.chaseSW, field.chaseNW]
	K.ball = ball
	K.assigned_half = dHalf
	K.aim_target = aimTarget
	K.own_goal = ownGoal.global_position
	K.opp_goal = oppGoal.global_position
	K.left_wall = field.leftWall
	K.right_wall = field.rightWall
	#TODO: if field type is road or wide road, else different
	K.leftPost = LPost
	K.rightPost = RPost
	K.back_wall = keeperWall
	K.oppKeeper = oppK
	K.oppLF = oppLF
	K.oppRF = oppRF
	K.buddyLF = LF
	K.buddyRF = RF
	LG.defending_goal_position = ownGoal.global_position
	LG.assigned_half = dHalf
	LG.aim_target = aimTarget
	LG.ball = ball
	LG.leftPost = LPost
	LG.rightPost = RPost
	LG.buddy_guard = RG
	LG.is_lead_guard = true
	LG.plays_left_side = true
	LG.assigned_forward = oppRF
	LG.other_forward = oppLF
	LG.buddy_keeper = K
	LG.opp_keeper = oppK
	RG.defending_goal_position = ownGoal.global_position
	RG.aim_target = aimTarget
	RG.buddy_guard = LG
	RG.assigned_forward = oppLF
	RG.other_forward = oppRF
	RG.leftPost = LPost
	RG.rightPost = RPost
	RG.buddy_keeper = K
	RG.opp_keeper = oppK
	RG.ball = ball
	RG.assigned_half = dHalf
	RG.plays_left_side = false
	LF.goal_position = oppGoal.global_position
	LF.assigned_guard = oppRG
	LF.opposing_keeper = oppK
	LF.forward_partner = RF
	LF.ball = ball
	LF.plays_left_side = true
	LF.buddy_keeper = K
	LF.assigned_half = oHalf
	LF.waiting_point = LfWaiting.global_position
	RF.waiting_point = RfWaiting.global_position
	RF.goal_position = oppGoal.global_position
	RF.assigned_guard = oppLG
	RF.opposing_keeper = oppK
	RF.forward_partner = LF
	RF.ball = ball
	RF.buddy_keeper = K
	RF.assigned_half = oHalf
	RG.plays_left_side = false

func default_grooves():
	P.set_default_groove()
	K.set_default_groove()

func wipe_player_control():
	P.is_controlling_player = false
	K.is_controlling_player = false
	LG.is_controlling_player = false
	RG.is_controlling_player = false
	LF.is_controlling_player = false
	RF.is_controlling_player = false
	
func assign_player_control():
	if is_on_offense:
		P.is_controlling_player = true
	else:
		K.is_controlling_player = true
		
func set_team_id(id):
	team_id = id
	K.team = id
	P.team = id
	RG.team = id
	RF.team = id
	LG.team = id
	LF.team = id
	
func allow_movement():
	K.can_move = true
	K.current_behavior = "defending"
	#P.can_move = true #TODO: depends on what pitcher does after pitching
	RG.can_move = true
	RF.can_move = true
	LG.can_move = true
	LF.can_move = true
	LF.current_behavior = "target_man"
	
	#default state for once the team can play
func default_human_state():
	K.is_controlling_player = true
	K.child_state()
	K.current_behavior = "waiting"
	LG.is_controlling_player = false
	LG.child_state()
	RG.is_controlling_player = false
	RG.child_state()
	LF.is_controlling_player = false
	LF.child_state()
	LF.current_behavior = "target_man"
	RF.is_controlling_player = false
	RF.child_state()
	RF.current_behavior = "shooter"
	#TODO:forwards
	
	#default state for once the team can play
func default_ai_state():
	K.is_controlling_player = false
	K.child_state()
	LG.is_controlling_player = false
	LG.child_state()
	RG.is_controlling_player = false
	RG.child_state()
	LF.child_state()
	LF.current_behavior = "rebound"
	
func nextPlayStatus():
	K.reset_state()
	K.has_guessed = false
	LG.reset_state()
	RG.reset_state()
	LF.reset_state()
	RF.reset_state()
	P.reset_state()
	P.human_ready = false
	bench_rest()
	
func fire_up_bench():
	for player in bench:
		player.add_groove(20)
		player.add_energy(10)
		
func bench_rest():
	for player in bench:
		player.lose_groove(1)
		player.add_energy(5)

func switch_zone():
	if LG.strategy.zone:
		LG.strategy.zone = false
		RG.strategy.zone = false
	else:
		LG.strategy.zone = true
		RG.strategy.zone = true
	print("Zone? ", LG.strategy.zone)

func debug_default_roster():
	# Clear existing roster first
	roster.clear()
	bench.clear()
	
	# P1 is an enforcer pitcher
	var P1 = Reworked_Pitcher.new()
	P1.position_type = "pitcher"
	P1.bio = {"first_name": "Billy", "last_name": "Knuckles", "leftHanded": false}
	P1.attributes = {
		"speedRating": 65, 
		"speed": 100.0, 
		"sprint_speed": 120.0, 
		"blocking": 50, 
		"positioning": 50,
		"aggression": 90,
		"reactions": 50,
		"durability": 75,
		"power": 70,  
		"endurance": 60, 
		"accuracy": 55,   
		"balance": 85,	
		"focus": 60,  
		"shooting": 90,	
		"toughness": 90,
		"confidence": 60 
	}
	
	# P2 is a lightweight pitcher
	var P2 = Reworked_Pitcher.new()
	P2.position_type = "pitcher"
	P2.bio = {"first_name": "Randy", "last_name": "Runningham", "leftHanded": true}
	P2.attributes = {
		"speedRating": 85, 
		"speed": 120.0, 
		"sprint_speed": 160.0, 
		"blocking": 50, 
		"positioning": 50,
		"aggression": 50,
		"reactions": 70,
		"durability": 55,
		"power": 60,  
		"endurance": 80, 
		"accuracy": 65,   
		"balance": 65,	
		"focus": 80,  
		"shooting": 50,	
		"toughness": 52,
		"confidence": 71 
	}
	
	# P3 is an anti-keeper forward
	var P3 = Forward.new()
	P3.position_type = "forward"
	P3.bio = {"first_name": "Mike", "last_name": "Torpedo", "leftHanded": false}
	P3.attributes = {
		"speedRating": 80, 
		"speed": 115.0, 
		"sprint_speed": 150.0, 
		"blocking": 50, 
		"positioning": 50,
		"aggression": 87,
		"reactions": 60,
		"durability": 75,
		"power": 87,  
		"endurance": 66, 
		"accuracy": 75,   
		"balance": 85,	
		"focus": 60,  
		"shooting": 60,	
		"toughness": 90,
		"confidence": 60 
	}
	
	# P4 is a solid guard
	var P4 = Guard.new()
	P4.position_type = "guard"
	P4.bio = {"first_name": "Kyle", "last_name": "Korpisalo", "leftHanded": false}
	P4.attributes = {
		"speedRating": 70, 
		"speed": 105.0, 
		"sprint_speed": 130.0, 
		"blocking": 70, 
		"positioning": 84,
		"aggression": 87,
		"reactions": 65,
		"durability": 95,
		"power": 80,  
		"endurance": 76, 
		"accuracy": 70,   
		"balance": 80,	
		"focus": 60,  
		"shooting": 65,	
		"toughness": 80,
		"confidence": 60 
	}
	
	# Add players to roster and bench
	add_player(P1)
	add_player(P2)
	add_player(P3)
	add_player(P4)
