class_name BallPlayer
extends CharacterBody2D

## Core Attributes
enum PlayerState {
	IDLE,
	GO_TO_POSITION,
	SOLO_CELEBRATION,
	TEAM_CELEBRATION,
	IN_BRAWL,
	OUT_BRAWL,
	AI_OUT_BRAWL,
	CHILD_STATE #means character is using some child's state as primary operation
}

enum BrawlType {
	HOCKEY_AREA,
	FOOTBALL_AREA,
	ALL_OUT
}

## Physical Attributes
@export var first_name: String = "John"
@export var last_name: String = "Player"
@export var nickname: String = ""
@export var hometown: String = "Anytown"
@export var height: float = 1.8 # in meters
@export var weight: float = 80.0 # in kg
@export var age: int = 25

## Visible Stats
@export var power: float = 1.0 #affects throwing and batting the ball
@export var control: float = 1.0 #affects randomness of passes and pitches
@export var focus: float = 1.0 #affects catching and defense
@export var speed: float = 200.0 #running speed
@export var sprint_speed: float = 275 #top speed
@export var catch_rating: float = 0.5 #base catch chance
@export var jump_height: float = 1.0 #affects catching high balls
@export var strength: float = 1.0 #impacts stiff arm, blocking, and attack
@export var dodge: float = 1.0 #spin effectiveness
@export var balance: int = 3 #affects chance to be tackled or stiff armed
@export var health: int = 10#affects training and survival
## Hidden Stats
@export var max_athleticism: float = 1.0
@export var max_skill: float = 1.0
@export var max_mental: float = 1.0
@export var max_tough: float = 1.0
@export var determination: float = 1.0 #affects training
## Energy System
@export var energy: float = 100.0 #current player energy. always between 0-100
@export var endurance: float = 1.0 #affects speed, focus, and fighting
@export var toughness: float = 1.0 #affects fighting
@export var durability: float = 1.0 #affects injury chance

## Brawl System
var current_state: PlayerState = PlayerState.IDLE
var brawl_type: BrawlType = BrawlType.HOCKEY_AREA
var brawl_target_position: Vector2 = Vector2.ZERO
var brawl_team_hp: float = 100.0
var brawl_opponent_hp: float = 100.0
var is_injured: bool = false
var injury_type: String = ""
var injury_debuffs: Dictionary = {}

## Nodes
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
#@onready var sprite: Sprite2D = $Sprite

#housekeeping
var is_player_controlled
var can_move
var has_ball
var ball

signal state_changed(new_state: PlayerState)
signal energy_changed(new_value: float)
signal brawl_started(brawl_type: BrawlType)
signal brawl_ended(winning_team: bool)
signal player_injured(injury_type: String)

func _ready():
	# Initialize any default values
	update_injury_effects()

func _physics_process(delta):
	match current_state:
		PlayerState.IDLE:
			idle_behavior(delta)
			can_move = false
		PlayerState.GO_TO_POSITION:
			go_to_position_behavior(delta)
		PlayerState.SOLO_CELEBRATION:
			solo_celebration_behavior(delta)
		PlayerState.TEAM_CELEBRATION:
			team_celebration_behavior(delta)
		PlayerState.IN_BRAWL:
			in_brawl_behavior(delta)
		PlayerState.OUT_BRAWL:
			out_brawl_behavior(delta)
		PlayerState.AI_OUT_BRAWL:
			ai_out_brawl_behavior(delta)
		PlayerState.CHILD_STATE:
			can_move = true
	
	# Energy recovery
	if energy < 100.0:
		energy = min(energy + endurance * delta * 10, 100.0)
		energy_changed.emit(energy)

func idle_behavior(delta):
	# Default idle behavior
	velocity = Vector2.ZERO
	#play_idle_animation()

func go_to_position_behavior(delta):
	# Move to assigned position
	var target_pos = get_assigned_position()
	var direction = (target_pos - global_position).normalized()
	velocity = direction * speed * delta
	
	if global_position.distance_to(target_pos) < 10.0:
		transition_state(PlayerState.IDLE)
	
	move_and_slide()

func solo_celebration_behavior(delta):
	# Play solo celebration animation
	#if not animation_player.is_playing():
		#animation_player.play("solo_celebration")
	
	# Random movement during celebration
	velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed * 0.5 * delta
	move_and_slide()

func team_celebration_behavior(delta):
	# Move toward celebration center point
	var celebration_center = get_celebration_center()
	var direction = (celebration_center - global_position).normalized()
	velocity = direction * speed * 0.3 * delta
	
	if global_position.distance_to(celebration_center) < 20.0:
		print("celebrate")
		#if not animation_player.is_playing():
			#animation_player.play("team_celebration")
	
	move_and_slide()

func in_brawl_behavior(delta):
	# Stay engaged in brawl
	velocity = Vector2.ZERO
	play_brawl_animation()

func out_brawl_behavior(delta):
	# Player-controlled movement to join brawl
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	velocity = input_vector.normalized() * speed * delta
	move_and_slide()
	
	# Check if reached brawl position
	if global_position.distance_to(brawl_target_position) < 20.0:
		join_brawl()
	
	# Brawl commands
	if Input.is_action_just_pressed("brawl_attack"):
		brawl_attack()
	if Input.is_action_just_pressed("brawl_block"):
		brawl_block()

func ai_out_brawl_behavior(delta):
	# AI-controlled movement to join brawl
	var direction = (brawl_target_position - global_position).normalized()
	velocity = direction * speed * delta
	move_and_slide()
	
	# Check if reached brawl position
	if global_position.distance_to(brawl_target_position) < 20.0:
		join_brawl()

func transition_state(new_state: PlayerState):
	current_state = new_state
	state_changed.emit(new_state)
	
	# State-specific initialization
	match new_state:
		PlayerState.SOLO_CELEBRATION:
			print("celebrate alone")
			#animation_player.stop()
		PlayerState.TEAM_CELEBRATION:
			print("celebrate with the boys")
			#animation_player.stop()
		PlayerState.IN_BRAWL:
			play_brawl_animation()
		PlayerState.OUT_BRAWL, PlayerState.AI_OUT_BRAWL:
			brawl_target_position = get_brawl_position()

#func play_idle_animation():
	#if not animation_player.is_playing():
		#animation_player.play("idle")

func play_brawl_animation():
	print("gloves off")
	#if not animation_player.is_playing():
		#animation_player.play("brawl_idle")

func get_assigned_position() -> Vector2:
	# Implement based on your game's position system
	return Vector2.ZERO

func get_celebration_center() -> Vector2:
	# Implement based on celebration system
	return Vector2.ZERO

func get_brawl_position() -> Vector2:
	# Implement based on brawl location
	return Vector2.ZERO

## Brawl System Functions
func start_brawl(brawl_type: BrawlType):
	self.brawl_type = brawl_type
	determine_brawl_participants()
	brawl_started.emit(brawl_type)

func determine_brawl_participants():
	# Determine which players should be in brawl based on type
	match brawl_type:
		BrawlType.HOCKEY_AREA:
			# Only hockey-area players (goalie, outfielder, pitcher, batter)
			if is_hockey_area_player():
				transition_state(PlayerState.IN_BRAWL)
			elif is_closest_to_brawl() and is_on_player_team():
				transition_state(PlayerState.OUT_BRAWL)
			elif is_closest_to_brawl() and not is_on_player_team():
				transition_state(PlayerState.AI_OUT_BRAWL)
		BrawlType.FOOTBALL_AREA:
			# Only football-area players (catcher, football players)
			if is_football_area_player():
				transition_state(PlayerState.IN_BRAWL)
			elif is_closest_to_brawl() and is_on_player_team():
				transition_state(PlayerState.OUT_BRAWL)
			elif is_closest_to_brawl() and not is_on_player_team():
				transition_state(PlayerState.AI_OUT_BRAWL)
		BrawlType.ALL_OUT:
			# All players
			if is_closest_to_brawl() and is_on_player_team():
				transition_state(PlayerState.OUT_BRAWL)
			elif is_closest_to_brawl() and not is_on_player_team():
				transition_state(PlayerState.AI_OUT_BRAWL)
			else:
				transition_state(PlayerState.IN_BRAWL)

func is_hockey_area_player() -> bool:
	# Implement based on your player types
	return false

func is_football_area_player() -> bool:
	# Implement based on your player types
	return false

func is_closest_to_brawl() -> bool:
	# Implement logic to determine if this player is closest to brawl
	return false

func is_on_player_team() -> bool:
	# Implement team checking logic
	return true

func join_brawl():
	transition_state(PlayerState.IN_BRAWL)
	# Trigger next closest player to join
	trigger_next_brawl_participant()

func trigger_next_brawl_participant():
	# Implement logic to find next closest player and set their state
	pass

func brawl_attack():
	if energy <= 0:
		return
	
	# Calculate attack damage based on toughness and number of brawlers
	var brawlers = get_brawlers_on_team()
	var attack_power = toughness * (0.5 + brawlers.size() * 0.1)
	
	# Apply damage to opponent team
	brawl_opponent_hp -= attack_power
	
	# Consume energy
	energy = max(0, energy - 15)
	energy_changed.emit(energy)
	
	# Check for brawl end
	if brawl_opponent_hp <= 0:
		end_brawl(true)

func brawl_block():
	if energy <= 0:
		return
	
	# Calculate block effectiveness
	var block_power = toughness * 0.8
	var stun_duration = block_power * 0.5
	
	# Apply stun to opponents
	apply_opponent_stun(stun_duration)
	
	# Consume energy
	energy = max(0, energy - 10)
	energy_changed.emit(energy)

func apply_opponent_stun(duration: float):
	# Implement stun logic for opponents
	pass

func end_brawl(win: bool):
	if win:
		handle_brawl_victory()
	else:
		handle_brawl_defeat()
	
	# Reset all players to idle
	transition_state(PlayerState.IDLE)
	brawl_ended.emit(win)

func handle_brawl_victory():
	# Determine injuries for winning team
	determine_injuries(true)
	
	# Start celebration
	if randf() > 0.7: # 70% chance for team celebration
		transition_state(PlayerState.TEAM_CELEBRATION)
	else:
		transition_state(PlayerState.SOLO_CELEBRATION)

func handle_brawl_defeat():
	# Determine injuries for losing team
	determine_injuries(false)
	
	# Go back to position
	transition_state(PlayerState.GO_TO_POSITION)

func determine_injuries(is_winner: bool):
	if is_winner:
		# Winners can get hand injuries
		if randf() > durability * 0.8: # 20% base chance reduced by durability
			apply_injury("hand")
		
		# For each winner, check if they injure a loser
		var losers = get_losing_brawlers()
		if losers.size() > 0:
			var target = losers[randi() % losers.size()]
			target.apply_random_injury()
	else:
		# Losers get random injuries
		apply_random_injury()

func apply_random_injury():
	var injury_roll = randf()
	var injury_threshold = durability * 0.7 # Higher durability = less chance
	
	if injury_roll > injury_threshold * 1.2: # 20% base chance for severe
		apply_injury("severe")
	elif injury_roll > injury_threshold * 0.9: # 10% base chance for head
		apply_injury("head")
	elif injury_roll > injury_threshold * 0.7: # 20% base chance for leg
		apply_injury("leg")
	elif injury_roll > injury_threshold * 0.5: # 20% base chance for hurt
		apply_injury("hurt")

func apply_injury(type: String):
	is_injured = true
	injury_type = type
	
	# Apply debuffs based on injury type
	match type:
		"hand":
			injury_debuffs = {
				"toughness": -1,
				"catch_rating": -1
			}
		"hurt":
			injury_debuffs = {
				"power": -1,
				"control": -1,
				"focus": -1,
				"speed": -1,
				"catch_rating": -1,
				"tackle_rating": -1
			}
		"leg":
			injury_debuffs = {
				"speed": -5,
				"strength": -5,
				"power": -5
			}
		"head":
			injury_debuffs = {
				"focus": -5,
				"catch_rating": -5,
				"endurance": -5,
				"durability": -5
			}
		"severe":
			injury_debuffs = {
				"power": -5,
				"control": -5,
				"focus": -5,
				"speed": -5,
				"catch_rating": -5,
				"tackle_rating": -5,
				"strength": -5,
				"toughness": -5,
				"endurance": -5,
				"durability": -5
			}
	
	update_injury_effects()
	player_injured.emit(type)

func update_injury_effects():
	# Apply all debuffs from injury
	for stat in injury_debuffs:
		if injury_debuffs.has(stat):
			set(stat, get(stat) + injury_debuffs[stat])

func heal_injury():
	# Remove all debuffs from injury
	for stat in injury_debuffs:
		if injury_debuffs.has(stat):
			set(stat, get(stat) - injury_debuffs[stat])
	
	is_injured = false
	injury_type = ""
	injury_debuffs = {}

func get_brawlers_on_team() -> Array:
	# Implement logic to get all brawlers on same team
	return []

func get_losing_brawlers() -> Array:
	# Implement logic to get all brawlers on losing team
	return []
	
func move_towards(target: Vector2, delta: float):
	sprint_towards(target, delta, false)
	
func sprint_towards(target: Vector2, delta: float, isSprinting: bool):
	var direction = (target - position).normalized()
	var go_speed
	if isSprinting:
		go_speed = sprint_speed
	else:
		go_speed = speed
	velocity = direction * go_speed * delta
	move_and_slide()
