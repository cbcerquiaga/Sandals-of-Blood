class_name Team
extends Node

var team_id: int
var is_on_offense: bool
var is_player_team: bool
var roster: Array[Player] = [] #every player on the team
var bench: Array[Player] = []
var buffs: Array[Dictionary] = []
var pending_substitutions: Array[Substitution] = []
var strategy: Dictionary = {
	"base_aggression": 1.0,
	"position_aggression": {
		"keeper": 1.0,
		"guard": 1.0,
		"forward": 1.0,
		"pitcher": 1.0
	},
	"substitution": {
		"energy_threshold": 30.0,
		"injury_threshold": 3,
		"priority": ["pitcher", "keeper", "forward", "guard"]
	},
	"brawling": {
		"max_in": 3,
		"urgency": 0.7,
		"attack_tendency": 0.6,
		"block_tendency": 0.3
	},
	"tactics": {
		"LF": {},
		"LF_title": "Classic Forward",
		"RF": {},
		"RF_title": "Rusher",
		"D": {},
		"D_title": "Positional Man to Man"
	}
}

@export var K: Keeper
@export var P: Reworked_Pitcher
@export var LG: Guard
@export var RG: Guard
@export var LF: Forward
@export var RF: Forward
@export var subs_remaining: int = 6 #sub every starter off the field; play all of your team's pitchers and sub 3 fielders; sub through all but one of your team's pitchers and sub all your fielders except your goalkeeper


@onready var onfield_players = [K, P, LG, RG, LF, RF]
@onready var next_onfield_players: Array
@onready var next_bench: Array
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
	reset_subs()
	add_players_to_roster()
	initialize_default_strategy()
	next_roster_no_subs()
	
func _process(delta: float) -> void:
	if !has_readied:
		if K.attributes.power != null && LF.attributes.power != null:
			has_readied = true
			on_team_ready.emit(team_id)
			
func change_all_players():
	change_player("LG", next_onfield_players[0])
	change_player("RG", next_onfield_players[1])
	change_player("LF", next_onfield_players[2])
	change_player("RF", next_onfield_players[3])
	change_player("K", next_onfield_players[4])
	change_player("P", next_onfield_players[5])

func change_player(position, newPlayer):
	#[LG, RG, LF, RF, K, P]
	match position:
		"LG":
			onfield_players[0].set_all_properties(newPlayer)
		"RG":
			onfield_players[1].set_all_properties(newPlayer)
		"LF":
			onfield_players[2].set_all_properties(newPlayer)
		"RF":
			onfield_players[3].set_all_properties(newPlayer)
		"K":
			onfield_players[4].set_all_properties(newPlayer)
		"P":
			onfield_players[5].set_all_properties(newPlayer)

# Revert pending substitutions
func revert_pending_substitutions() -> void:
	pending_substitutions.clear()
	#TODO
	pass
	
func next_roster_no_subs():
	next_onfield_players = onfield_players
	next_bench = bench
	
func update_substitute_info(temp_player: Player, other: Player):
	temp_player.bio = other.bio
	temp_player.attributes = other.attributes
	temp_player.playable_positions = other.playable_positions
	temp_player.preferred_position = other.preferred_position
	temp_player.status = other.status.duplicate()
	temp_player.game_stats = other.game_stats
	temp_player.special_pitch_names = other.special_pitch_names
	temp_player.special_pitch_groove = other.special_pitch_groove
	temp_player.team = other.team
	return temp_player
	
func add_pending_substitution(sub: Substitution):
	pending_substitutions.append(sub)

func export_to_dict() -> Dictionary:
	var data = {
		"roster": [],
		"strategy": strategy.duplicate(true)
	}
	for player in roster:
		data["roster"].append(player.export_to_dict())
	return data

func import_from_dict(data: Dictionary):
	strategy = data["strategy"].duplicate(true)
	roster.clear()
	bench.clear()
	for player_data in data["roster"]:
		var player = Player.new()
		player.import_from_dict(player_data)
		add_player(player)

func initialize_default_strategy():
	strategy.position_aggression = {
		"keeper": 0.6,
		"guard": 1.2,
		"forward": 1.5,
		"pitcher": 0.3
	}

func add_players_to_roster():
	add_player(K)
	add_player(P)
	add_player(LG)
	add_player(RG)
	add_player(RF)
	add_player(LF)
	onfield_players = [LG, RG, LF, RF, K, P] #this order is important!
	
func reset_subs():
	subs_remaining = 6

func add_player(player: Player):
	roster.append(player)
	bench.append(player)
	player.team = team_id
	apply_team_buffs(player)

func apply_team_buffs(player: Player):
	for buff in buffs:
		player.add_buff(buff["name"], buff["modifiers"])

func add_team_buff(buff_name: String, modifiers: Dictionary, duration: float = -1):
	var buff_data = {
		"name": buff_name,
		"modifiers": modifiers,
		"duration": duration,
	}
	buffs.append(buff_data)
	for player in roster:
		player.add_buff(buff_name, modifiers)

func remove_team_buff(buff_name: String):
	for i in range(buffs.size() - 1, -1, -1):
		if buffs[i]["name"] == buff_name:
			buffs.remove_at(i)
	for player in roster:
		player.remove_buff(buff_name)

#durations are measured in pitches
func update_buff_durations():
	for i in range(buffs.size() - 1, -1, -1):
		var buff = buffs[i]
		if buff["duration"] > 0:
			buff["duration"] -= 1
			if buff["duration"] <= 0:
				remove_team_buff(buff["name"])


func get_modified_aggression(base_aggression: float, position_type: String) -> float:
	var pos_aggression = strategy.position_aggression.get(position_type, 1.0)
	var team_aggression = strategy.base_aggression
	var aggression_mod = 1.0
	for buff in buffs:
		if buff.modifiers.has("aggression"):
			aggression_mod += buff.modifiers.aggression / 100.0
	return base_aggression * pos_aggression * team_aggression * aggression_mod


func enlighten(aimTarget, ball, field, keeperWall, ownGoal, oppGoal, oppP, oppK, oppLG, oppRG, oppLF, oppRF, LfWaiting, RfWaiting, LPost, RPost, dHalf, oHalf, rest, lBanks, rBanks):
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
	ball.pitch_side.connect(K._on_ball_emit_pitch_side)
	K.assigned_half = dHalf
	K.aim_target = aimTarget
	K.own_goal = ownGoal.global_position
	K.opp_goal = oppGoal.global_position
	K.left_wall = field.leftWall
	K.right_wall = field.rightWall
	K.leftPost = LPost
	K.rightPost = RPost
	K.back_wall = keeperWall
	K.oppKeeper = oppK
	K.oppLF = oppLF
	K.oppRF = oppRF
	K.buddyLF = LF
	K.buddyRF = RF
	K.buddyLG = LG
	K.buddyRG = RG
	LG.defending_goal_position = ownGoal.global_position
	LG.assigned_half = dHalf
	LG.aim_target = aimTarget
	LG.ball = ball
	LG.leftPost = LPost
	LG.rightPost = RPost
	LG.buddy_guard = RG
	LG.buddySSF = LF
	LG.buddyWSF = RF
	LG.oppLG = oppLG
	LG.oppRG = oppRG
	LG.is_lead_guard = true
	LG.plays_left_side = true
	LG.assigned_forward = oppRF
	LG.other_forward = oppLF
	LG.buddy_keeper = K
	LG.opp_keeper = oppK
	LG.aim_selection = lBanks
	RG.defending_goal_position = ownGoal.global_position
	RG.aim_target = aimTarget
	RG.buddy_guard = LG
	RG.assigned_forward = oppLF
	RG.other_forward = oppRF
	RG.leftPost = LPost
	RG.rightPost = RPost
	RG.buddy_keeper = K
	RG.opp_keeper = oppK
	RG.buddySSF = RF
	RG.buddyWSF = LF
	RG.ball = ball
	RG.oppLG = oppLG
	RG.oppRG = oppRG
	RG.assigned_half = dHalf
	RG.aim_selection = rBanks
	RG.plays_left_side = false
	LF.goal_position = oppGoal.global_position
	LF.assigned_guard = oppRG
	LF.other_guard = oppLG
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
	RF.other_guard = oppRG
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
	RG.can_move = true
	RF.can_move = true
	LG.can_move = true
	LF.can_move = true
	LF.current_behavior = "target_man"

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
	update_field()
	K.reset_state()
	K.has_guessed = false
	LG.reset_state()
	RG.reset_state()
	LF.reset_state()
	RF.reset_state()
	P.reset_state()
	P.human_ready = false
	bench_rest()
	
func update_field():
	var current_players = [LG, RG, LF, RF, K, P]
	var saved_ball = K.ball# players MUST know ball
	for i in range(current_players.size()):
		current_players[i].set_all_properties(next_onfield_players[i])
		current_players[i].ball = saved_ball
		current_players[i].reset_state()
		current_players[i].can_move = false
		current_players[i].velocity = Vector2.ZERO
		current_players[i].restore_behaviors()
	bench = next_bench
	onfield_players = current_players
	if P.ball != saved_ball:
		P.ball = saved_ball
		if P.ball_pitched.is_connected(saved_ball.be_pitched):
			P.ball_pitched.disconnect(saved_ball.be_pitched)
		P.ball_pitched.connect(saved_ball.be_pitched)
		if P.special_pitched.is_connected(saved_ball.be_special_pitched):
			P.special_pitched.disconnect(saved_ball.be_special_pitched)
		P.special_pitched.connect(saved_ball.be_special_pitched)
	LG.position_type = "guard"
	RG.position_type = "guard"
	LF.position_type = "forward"
	RF.position_type = "forward"
	K.position_type = "keeper"
	P.position_type = "pitcher"

func print_sub_on():
	var string
	for sub in pending_substitutions:
		string = sub.sub_position + " - " + sub.playerOn.bio.first_name[0] + ". " + sub.playerOn.bio.last_name + "\n"
		
func print_sub_off():
	var string
	for sub in pending_substitutions:
		string = sub.sub_position + " - " + sub.playerOff.bio.first_name[0] + ". " + sub.playerOff.bio.last_name + "\n"

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
	roster.clear()
	bench.clear()
	
	# Create players as base Player class
	var P1 = Player.new()
	P1.position_type = "pitcher"
	P1.playable_positions = ["P"]
	P1.declared_pitcher = true
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
		"throwing": 75,
		"endurance": 60, 
		"accuracy": 55,   
		"balance": 85,    
		"focus": 60,  
		"shooting": 90,    
		"toughness": 90,
		"confidence": 60 
	}
	#TODO: figure out why I have to set variables to the exact types instead of just passing them in directly
	var pitches: Array[String] = ["yoyo, knuckler, corker"]
	var grooves: Array[float] = [25, 35, 45]
	P1.special_pitch_names = pitches
	P1.special_pitch_groove = grooves
	P1.playable_positions = ["P", "LG"]
	P1.preferred_position = "P"
	P1.bio = {
	"first_name" :"Billy",
	"last_name": "Knuckles",
	"nickname": "Fistmaster",
	"hometown": "Wasteland",
	"leftHanded": true,
	"feet": 6,
	"inches": 4,
	"pounds": 255,
	"years": 29
}
	
	var P2 = Player.new()
	P2.position_type = "pitcher"
	P2.declared_pitcher = true
	P2.portrait = "res://Assets/Player Portraits/placeholder portrait 2.png"
	pitches = ["zig-zag, looper, bouncer"]
	grooves = [15, 20, 25]
	P2.special_pitch_names = pitches
	P2.special_pitch_groove = grooves
	P2.playable_positions = ["P", "K", "LG", "RG", "LF", "RF"]
	P2.preferred_position = "P"
	P2.bio = {
	"first_name" :"Randy",
	"last_name": "Runningham",
	"nickname": "The Ostrich",
	"hometown": "New Beach",
	"leftHanded": false,
	"feet": 6,
	"inches": 1,
	"pounds": 155,
	"years": 22
}
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
		"throwing": 99,
		"endurance": 80, 
		"accuracy": 65,   
		"balance": 65,    
		"focus": 80,  
		"shooting": 50,    
		"toughness": 52,
		"confidence": 71 
	}
	
	var P3 = Player.new()
	P3.position_type = "forward"
	P3.playable_positions = ["LF", "RF"]
	P3.preferred_position = "RF"
	P3.portrait = "res://Assets/Player Portraits/placeholder_portrait 3.png"
	P3.bio = {
	"first_name" :"Mike",
	"last_name": "Lillard",
	"nickname": "The Torpedo",
	"hometown": "Discount Auto Parts",
	"leftHanded": true,
	"feet": 5,
	"inches": 9,
	"pounds": 205,
	"years": 34
}
	P3.attributes = {
		"speedRating": 80, 
		"speed": 115.0, 
		"sprint_speed": 150.0, 
		"blocking": 50, 
		"positioning": 50,
		"aggression": 87,
		"reactions": 60,
		"throwing": 50,
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
	
	var P4 = Player.new()
	P4.position_type = "guard"
	P4.playable_positions = ["RG"]
	P4.portrait = "res://Assets/Player Portraits/placeholder portrait 4.png"
	P4.bio = {
	"first_name" :"Kyle",
	"last_name": "Korpisalo",
	"nickname": "Killer",
	"hometown": "Wasteland",
	"leftHanded": false,
	"feet": 6,
	"inches": 0,
	"pounds": 145,
	"years": 19
}
	P4.attributes = {
		"speedRating": 70, 
		"speed": 105.0, 
		"sprint_speed": 130.0, 
		"blocking": 70, 
		"positioning": 84,
		"aggression": 87,
		"reactions": 65,
		"durability": 95,
		"throwing": 60,
		"power": 80,  
		"endurance": 76, 
		"accuracy": 70,   
		"balance": 80,    
		"focus": 60,  
		"shooting": 65,    
		"toughness": 80,
		"confidence": 60 
	}
	
	# Add players
	add_player(P1)
	add_player(P2)
	add_player(P3)
	add_player(P4)
	#change_all_players()
	
func applyTactics():
	print("applying tactics. D:",  strategy.tactics.D, ", LF:", strategy.tactics.LF, ", RF:", strategy.tactics.RF)
	LG.defense_strategy = strategy.tactics.D
	RG.defense_strategy = strategy.tactics.D
	LF.forward_strategy = strategy.tactics.LF
	RF.forward_strategy = strategy.tactics.RF

func check_player_positions():
	for player in [K, LG, RG, LF, RF]:
		# Skip incapacitated players
		if player.check_is_incapacitated():
			continue
		if not player.is_in_half():
			# Override current behavior to return to assigned half
			player.needs_go_home = true
			player.move_towards_half()
		else:
			# Player is back in correct half, restore normal behavior
			if player.needs_go_home:
				player.needs_go_home = false
				# Restore appropriate behavior based on position and team state
				restore_player_behavior(player)

func restore_player_behavior(player: Player):
	match player.position_type:
		"keeper":
			player.current_behavior = "defending"
		"guard":
			if strategy.tactics.D.zone == false:
				player.current_behavior = "marking"
			else:
				if player.plays_left_side:
					if strategy.tactics.D.lg_trap:
						player.current_behavior = "trapping"
					else:
						player.current_behavior = "escorting"
				else:
					if strategy.tactics.D.rg_trap:
						player.current_behavior = "trapping"
					else:
						player.current_behavior = "escorting"
		"forward":
			player.make_strategy_decision()
