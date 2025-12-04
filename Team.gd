class_name Team
extends Node

var team_name: String
var team_city: String
var team_logo: String #path to the logo
var team_uniform_type: int #corresponds to type of uniform
var uni_color_1
var uni_color_2
var uni_color_3
var uni_color_4
var gk_color_1
var gk_color_2
var gk_color_3
var gk_color_4
var team_abbreviation: String
var team_name_inverted: bool = false #"town mascots" if false, "mascots of town" if true
var team_logo_path: String
var team_id: int
var is_on_offense: bool
var is_player_team: bool
var roster: Array[Player]= [] #every player on the team
var starters: Array[Player]= [] #used for stats, the players on the field when the game starts
var bench: Array[Player]= []
var buffs: Array[Dictionary] = []
@onready var gear_keeper: Equipment #assigned to whoever is the keeper
@onready var pending_substitutions = []
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

var game_stats: Dictionary = {
	"pitches" = 0, #how many pitches the team has thrown
	"goals" = 0, #goals scored
	"aces" = 0, #total goals aced
	"starter_goals" = 0, #goals from starters
	"bench_goals" = 0, #goals from substitutes
	"ball_in_half" = 0, #time the ball has spent in our half
	"touches" = 0, #number of times our players touch the ball, not including pitches
	"sacks" = 0
}

@export var K: Keeper
@export var P: Reworked_Pitcher
@export var LG: Guard
@export var RG: Guard
@export var LF: Forward
@export var RF: Forward
@export var subs_remaining: int = 6 #sub every starter off the field; play all of your team's pitchers and sub 3 fielders; sub through all but one of your team's pitchers and sub all your fielders except your goalkeeper


@onready var onfield_players: Array[Player] = [K, P, LG, RG, LF, RF]
@onready var next_onfield_players: Array[Player]
@onready var next_bench: Array[Player]
var has_readied
signal on_team_ready(id: int)

func _init():
	team_name = "Test Faces" #TODO: import from file
	team_city = "Test City"
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
	#if strategy.tactics.LF_title == "Goon":
		#print("LF is a goon. Anger: " + str(LF.status.anger) + " Current behavior: " + str(LF.current_behavior))
	if !has_readied:
		if K.attributes.power != null && LF.attributes.power != null:
			has_readied = true
			on_team_ready.emit(team_id)
			
func set_starters():
	for player in [K, LG, RG, LF, RF, P]:
		player.status.starter = true
		if bench.has(player):
			bench.erase(player)
			
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
	temp_player.special_pitch_names = other.special_pitch_names.duplicate()
	temp_player.special_pitch_groove = other.special_pitch_groove.duplicate()
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
	onfield_players = [LG, RG, LF, RF, K, P] #this order is important!
	add_player(K)
	K.field_position == "K"
	add_player(P)
	P.field_position == "P"
	add_player(LG)
	LG.field_position == "LG"
	add_player(RG)
	RG.field_position == "RG"
	add_player(RF)
	RF.field_position == "LF"
	add_player(LF)
	LF.field_position == "RF"
	
	
func reset_subs():
	subs_remaining = 6

func add_player(player: Player):
	if not is_player_in_roster(player):
		roster.append(player)
		player.team_node = self
		if not [K, LG, RG, LF, RF, P].has(player):
			bench.append(player)
		player.team = team_id
		apply_team_buffs(player)

func is_player_in_roster(player: Player) -> bool:
	for p in roster:
		if p.bio.first_name == player.bio.first_name and p.bio.last_name == player.bio.last_name:
			return true
	return false

func apply_team_buffs(player: Player):
	for buff in buffs:
		var buff_attributes = []
		var buff_values = []
		for attribute in buff["modifiers"]:
			buff_attributes.append(attribute)
			buff_values.append(buff["modifiers"][attribute])
		player.add_buff(buff["name"], buff_attributes, buff_values)

func add_team_buff(buff_name: String, modifiers: Dictionary, duration: float = -1):
	var buff_attributes = []
	var buff_values = []
	for attribute in modifiers:
		buff_attributes.append(attribute)
		buff_values.append(modifiers[attribute])
	
	var buff_data = {
		"name": buff_name,
		"modifiers": modifiers,
		"duration": duration,
	}
	buffs.append(buff_data)
	for player in roster:
		player.add_buff(buff_name, buff_attributes, buff_values)

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
		if buff.has("modifiers") and buff.modifiers.has("aggression"):
			aggression_mod += buff.modifiers.aggression / 100.0
	return base_aggression * pos_aggression * team_aggression * aggression_mod


func enlighten(aimTarget, ball, field, keeperWall, ownGoal, oppGoal, oppP, oppK, oppLG, oppRG, oppLF, oppRF, LfWaiting, RfWaiting, LPost, RPost, dHalf, oHalf, rest, lBanks, rBanks):
	P.field_position = "P"
	K.field_position = "K"
	LF.field_position = "LF"
	RF.field_position = "RF"
	LG.field_position = "LG"
	RG.field_position = "RG"
	P.ball = ball
	P.buddyK = K
	P.buddyLG = LG
	P.buddyRG = RG
	P.buddyLF = LF
	P.buddyRF = RF
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
	K.opposing_keeper = oppK
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
	LG.opposing_keeper = oppK
	LG.aim_selection = lBanks
	RG.defending_goal_position = ownGoal.global_position
	RG.aim_target = aimTarget
	RG.buddy_guard = LG
	RG.assigned_forward = oppLF
	RG.other_forward = oppRF
	RG.leftPost = LPost
	RG.rightPost = RPost
	RG.buddy_keeper = K
	RG.opposing_keeper = oppK
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
	#applyTactics()
	
func update_field():
	var saved_ball = K.ball# players MUST know ball
	
	# Update from next roster
	for i in range(onfield_players.size()):
		onfield_players[i].set_all_properties(next_onfield_players[i])
		#print("onfield player: defense strategy: " +  str(onfield_players[i].defense_strategy))
		onfield_players[i].ball = saved_ball
	
	bench = next_bench.duplicate(true)
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
	
	# Reset player states
	for player in onfield_players:
		player.reset_state()
		player.can_move = false
		player.velocity = Vector2.ZERO
		player.defense_strategy = strategy.tactics.D
		player.restore_behaviors()
	LF.forward_strategy = strategy.tactics.LF
	RF.forward_strategy = strategy.tactics.RF

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
	#roster.clear()
	#bench.clear()
	var K1 = Keeper.new()
	K1.playable_positions = ["K", "RG"]
	K1.special_ability = "machine"
	K1.declared_pitcher = false
	K1.attributes = {
		"speedRating": 75, 
		"speed": 110.0, 
		"sprint_speed": 130.0, 
		"blocking": 80, 
		"positioning": 80,
		"aggression": 60,
		"reactions": 80,
		"durability": 75,
		"power": 70,  
		"throwing": 45,
		"endurance": 70, 
		"accuracy": 65,   
		"balance": 75,    
		"focus": 60,  
		"shooting": 70,    
		"toughness": 70,
		"confidence": 70 ,
		"agility": 50
	}
	#TODO: figure out why I have to set variables to the exact types instead of just passing them in directly
	var pitches: Array[String] = ["chnageup", "moonball", "stop_go"]
	var grooves: Array[float] = [25, 35, 45]
	K1.special_pitch_names = pitches
	K1.special_pitch_groove = grooves
	K1.preferred_position = "K"
	K1.bio = {
	"first_name" :"Simon",
	"last_name": "Stopper",
	"nickname": "The Collander",
	"hometown": "Wasteland",
	"leftHanded": false,
	"feet": 5,
	"inches": 9,
	"pounds": 170,
	"years": 24
}
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
		"confidence": 60 ,
		"agility": 50,
		"faceoffs": 90
	}
	#TODO: figure out why I have to set variables to the exact types instead of just passing them in directly
	pitches  = ["flutter", "knuckler", "fake_curve"]
	grooves = [25, 35, 45]
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
	P1.encode_player_type("TP")
	var P0 = Player.new()
	P0.position_type = "pitcher"
	P0.declared_pitcher = true
	P0.portrait = "res://Assets/Player Portraits/placeholder portrait 2.png"
	pitches = ["changeup", "moonball", "stop_go"]
	grooves = [15, 20, 25]
	P0.special_pitch_names = pitches
	P0.special_pitch_groove = grooves
	P0.playable_positions = ["P", "K", "LG", "RG", "LF", "RF"]
	P0.preferred_position = "P"
	P0.bio = {
	"first_name" :"Filipe",
	"last_name": "Manu",
	"nickname": "The Trebuchet",
	"hometown": "New Beach",
	"leftHanded": false,
	"feet": 5,
	"inches": 6,
	"pounds": 140,
	"years": 27
}
	P0.attributes = {
		"speedRating": 85, 
		"speed": 120.0, 
		"sprint_speed": 160.0, 
		"blocking": 50, 
		"positioning": 50,
		"aggression": 50,
		"reactions": 70,
		"durability": 55,
		"power": 90,  
		"throwing": 90,
		"endurance": 60, 
		"accuracy": 75,   
		"balance": 65,    
		"focus": 90,  
		"shooting": 50,    
		"toughness": 32,
		"confidence": 71,
		"agility": 75,
		"faceoffs": 56 
	}
	P0.encode_player_type("AP")
	var P2 = Player.new()
	P2.position_type = "pitcher"
	P2.declared_pitcher = true
	P2.portrait = "res://Assets/Player Portraits/placeholder portrait 2.png"
	pitches = ["changeup", "moonball", "stop_go"]
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
		"shooting": 68,    
		"toughness": 72,
		"confidence": 71,
		"agility": 75,
		"faceoffs": 80 
	}
	P2.encode_player_type("HP")
	var P3 = Player.new()
	P3.position_type = "forward"
	P3.playable_positions = ["LF", "RF"]
	P3.preferred_position = "RF"
	P3.portrait = "res://Assets/Player Portraits/placeholder portrait 3.png"
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
		"confidence": 60,
		"agility": 65,
		"faceoffs": 60 
	}
	P3.encode_player_type("AF")
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
		"confidence": 60,
		"agility": 80 
	}
	P4.encode_player_type("SF")
	var G1 = Guard.new()
	G1.position_type = "guard"
	G1.preferred_position = "RG"
	G1.playable_positions = ["RG, LG"]
	G1.portrait = "res://Assets/Player Portraits/placeholder portrait 3.png"
	G1.bio = {
	"first_name" :"Vince",
	"last_name": "Thompson",
	"nickname": "Hitman",
	"hometown": "Crater City",
	"leftHanded": false,
	"feet": 5,
	"inches": 6,
	"pounds": 165,
	"years": 27
}
	G1.attributes = {
		"speedRating": 70, 
		"speed": 105.0, 
		"sprint_speed": 130.0, 
		"blocking": 80, 
		"positioning": 88,
		"aggression": 60,
		"reactions": 65,
		"durability": 65,
		"throwing": 60,
		"power": 70,  
		"endurance": 76, 
		"accuracy": 70,   
		"balance": 80,    
		"focus": 60,  
		"shooting": 85,    
		"toughness": 70,
		"confidence": 60,
		"agility": 80,
		"faceoffs": 50 
	}
	G1.encode_player_type("BG")
	var G2 = Guard.new()
	G2.position_type = "guard"
	G2.preferred_position = "LG"
	G2.playable_positions = ["LF, LG"]
	G2.portrait = "res://Assets/Player Portraits/placeholder portrait 4.png"
	G2.bio = {
	"first_name" :"Bertrand",
	"last_name": "Porter",
	"nickname": "Big Funky",
	"hometown": "Crater City",
	"leftHanded": false,
	"feet": 5,
	"inches": 11,
	"pounds": 235,
	"years": 23
}
	G2.attributes = {
		"speedRating": 60, 
		"speed": 95.0, 
		"sprint_speed": 120.0, 
		"blocking": 60, 
		"positioning": 78,
		"aggression": 90,
		"reactions": 65,
		"durability": 95,
		"throwing": 60,
		"power": 95,  
		"endurance": 86, 
		"accuracy": 70,   
		"balance": 80,    
		"focus": 60,  
		"shooting": 55,    
		"toughness": 70,
		"confidence": 60,
		"agility": 80,
		"faceoffs": 40 
	}
	G2.encode_player_type("DG")
	var F1 = Forward.new()
	F1.position_type = "forward"
	F1.preferred_position = "LF"
	F1.playable_positions = ["LF, LG"]
	F1.portrait = "res://Assets/Player Portraits/placeholder portrait 2.png"
	F1.bio = {
	"first_name" :"Norm",
	"last_name": "Gonzalez",
	"nickname": "Nacho",
	"hometown": "Grand Junction",
	"leftHanded": true,
	"feet": 5,
	"inches": 11,
	"pounds": 200,
	"years": 30
}
	F1.attributes = {
		"speedRating": 70, 
		"speed": 105.0, 
		"sprint_speed": 130.0, 
		"blocking": 80, 
		"positioning": 88,
		"aggression": 60,
		"reactions": 85,
		"durability": 85,
		"throwing": 60,
		"power": 80,  
		"endurance": 76, 
		"accuracy": 70,   
		"balance": 80,    
		"focus": 60,  
		"shooting": 65,    
		"toughness": 70,
		"confidence": 60,
		"agility": 80,
		"faceoffs": 66 
	}
	F1.encode_player_type("GF")
	var F2 = Guard.new()
	F2.position_type = "forward"
	F2.preferred_position = "RF"
	F2.playable_positions = ["LF, RF"]
	F2.portrait = "res://Assets/Player Portraits/placeholder portrait.png"
	F2.bio = {
	"first_name" :"Danton",
	"last_name": "Le Corbusier",
	"nickname": "Boyardee",
	"hometown": "New Beach",
	"leftHanded": false,
	"feet": 6,
	"inches": 6,
	"pounds": 215,
	"years": 26
}
	F2.attributes = {
		"speedRating": 60, 
		"speed": 95.0, 
		"sprint_speed": 120.0, 
		"blocking": 60, 
		"positioning": 78,
		"aggression": 90,
		"reactions": 65,
		"durability": 95,
		"throwing": 60,
		"power": 95,  
		"endurance": 86, 
		"accuracy": 70,   
		"balance": 80,    
		"focus": 60,  
		"shooting": 55,    
		"toughness": 70,
		"confidence": 60,
		"agility": 80,
		"faceoffs": 75 
	}
	F2.encode_player_type("CF")
	# Add players
	add_player(P1)
	add_player(P2)
	add_player(P3)
	add_player(P4)
	add_player(K1)
	add_player(G1)
	add_player(P0)
	K.set_all_properties(K1)
	RG.set_all_properties(G1)
	LG.set_all_properties(G2)
	RF.set_all_properties(F2)
	LF.set_all_properties(F1)
	
	K1.calculate_player_type()
	print("K1 type: " + K1.playStyle)
	P1.calculate_player_type()  
	P2.calculate_player_type()  
	P3.calculate_player_type()  
	P4.calculate_player_type()  
	G1.calculate_player_type()  
	print("G1 type: " + G1.playStyle)
	G2.calculate_player_type()  
	print("G2 type: " + G2.playStyle)
	F1.calculate_player_type()  
	print("F1 type: " + F1.playStyle)
	F2.calculate_player_type()  
	print("F2 type: " + F2.playStyle)
	
	#change_all_players()
	
func applyTactics():
	print("applying tactics. D:",  strategy.tactics.D, ", LF:", strategy.tactics.LF, ", RF:", strategy.tactics.RF)
	LG.defense_strategy = strategy.tactics.D
	RG.defense_strategy = strategy.tactics.D
	LF.forward_strategy = strategy.tactics.LF
	RF.forward_strategy = strategy.tactics.RF
	LG.update_behavior()
	print("LG tactics updated. LG: " + LG.bio.last_name + " strategy: " + str(LG.defense_strategy))
	RG.update_behavior()
	LF.choose_behavior()
	RF.choose_behavior()

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
			if player.defense_strategy.zone == false:
				player.handle_man_defense_behavior()
			else:
				player.handle_zone_defense_behavior()
		"forward":
			player.make_strategy_decision()

func add_pitch_played():
	P.game_stats.pitches_played += 1
	P.game_stats.pitches_p += 1
	K.game_stats.pitches_played += 1
	K.game_stats.pitches_k += 1
	LF.game_stats.pitches_played += 1
	LF.game_stats.pitches_f += 1
	RF.game_stats.pitches_played += 1
	RF.game_stats.pitches_f += 1
	LG.game_stats.pitches_played += 1
	LG.game_stats.pitches_g += 1
	RG.game_stats.pitches_played += 1
	RG.game_stats.pitches_g += 1

func reset_player_stats():
	P.reset_game_stats()
	K.reset_game_stats()
	LG.reset_game_stats()
	RG.reset_game_stats()
	LF.reset_game_stats()
	RF.reset_game_stats()

func get_time_in_half():
	var minutes = int(game_stats.ball_in_half/60)
	var seconds = int(game_stats.ball_in_half - (minutes * 60))
	var returnString = str(minutes) + ":"
	if seconds < 10:
		returnString += "0"
	returnString += str(seconds)
	return returnString
	
func execute_pending_substitutions():
	if pending_substitutions.is_empty():
		return
		
	for sub in pending_substitutions:
		var on_index = next_onfield_players.find(sub.playerOff)
		var off_index = next_bench.find(sub.playerOn)
		if on_index != -1 and off_index != -1:
			var temp = Player.new()
			temp.set_all_properties(next_onfield_players[on_index])
			next_onfield_players[on_index].set_all_properties(next_bench[off_index])
			next_bench[off_index].set_all_properties(temp)
			subs_remaining -= 1
	pending_substitutions = []
	
func validate_players():
	for player in roster:
		if player.special_pitch_names.size() != 3:
			print(player.bio.last_name +  " has no pitches. Correcting that.")
			player.special_pitch_names = ["none", "none", "none"]
		else:
			print(player.bio.last_name +  " throws these pitches: " + str(player.special_pitch_names))

func get_brawlers():
	var fielders = [K, LG, RG, LF, RF]
	var brawlers = []
	for player in fielders:
		if player.current_behavior == "brawling":
			brawlers.append(player)
	return brawlers

func anger(value):
	P.status.anger += value * (P.attributes.aggression/100)
	K.status.anger += value * (K.attributes.aggression/100)
	LG.status.anger += value* (LG.attributes.aggression/100)
	RG.status.anger += value * (RG.attributes.aggression/100)
	LF.status.anger += value* (LF.attributes.aggression/100)
	RF.status.anger += value * (RF.attributes.aggression/100)
	
func gwg_celebrate(scorer: Player):
	var hero
	for player in onfield_players:
		if player.has_same_name(scorer):
			player.solo_celebrate()
			hero = player
	for player in onfield_players:
		if !player.has_same_name(scorer):
			player.celebrations_star = hero
			player.team_celebrate()

func win_celebrate():
	for player in onfield_players:
		player.team_celebrate()
		
func lose_anti_celebrate():
	for player in onfield_players:
		player.lose()

func tie():
	for player in onfield_players:
		player.lose()
		
func apply_settings_buff(isHuman: bool):
	var buff_val
	if isHuman:
		buff_val = GlobalSettings.human_buff
	else:
		buff_val = GlobalSettings.cpu_buff
	var buff_stats = ["speed", "speed_rating", "sprint_speed", "blocking", "positioning", "reactions", "durability", "power", "throwing", "endurance", "accuracy", "balance", "focus", "shooting", "toughness", "confidence", "agility"] #everything but aggression because that's really a player's style more than ability
	var buff_vals = [buff_val,buff_val, buff_val*2,buff_val,buff_val,buff_val,buff_val,buff_val,buff_val,buff_val,buff_val,buff_val,buff_val,buff_val,buff_val,buff_val,buff_val]
	LF.add_buff("settings", buff_stats, buff_vals)
	RF.add_buff("settings", buff_stats, buff_vals)
	P.add_buff("settings", buff_stats, buff_vals)
	LG.add_buff("settings", buff_stats, buff_vals)
	RG.add_buff("settings", buff_stats, buff_vals)
	K.add_buff("settings", buff_stats, buff_vals)
	print("Got buffed: " + str(buff_val) + " Human team: " + str(isHuman))
