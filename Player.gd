extends CharacterBody2D
class_name Player

# Player Attributes
@export var attributes := {
	"speed": 110.0,
	"sprint_speed": 140.0,
	"blocking": 50, #scales player size?
	"positioning" : 90, #player's positioning ability
	"aggression": 50, #1-100, impacts decision making
	"reactions": 90, #1-100, impacts AI speed
	"durability": 75,	#1-100, impacts injury chance
	"power": 70,        # 1-100, affects hit strength
	"endurance": 60,    # 1-100, affects boost recovery and maximum boost
	"accuracy": 65,     # 1-100, affects shot precision  
	"balance": 55,		# 1-100, affects damage taken from hits
	"focus": 50,        # 1-100, affects curve control
	"shooting": 50,		# 1-100, affects shot and pass speed for forwards
	"toughness": 60,    # 1-100, brawl defense
	"confidence": 50    # 1-100, affects special moves
}

@export var status := {
	"energy": 100, #long-term endurance that depletes every pitch, also used for fighting
	"health": 100, #used for injuries
	"boost": 100, #short-term endurance that applies to sprinting and dodging, recovers immediately
	"max_energy": 100, #always 100
	"max_boost": 100, #variable dependent on energy
	"stability": 100, #fall chance, shoved chance
	"groove": 100 #affected by confidence
}

@export var bio := {
	"first_name" :"Johan",
	"last_name": "Baller",
	"nickname": "Bootycheeks",
	"hometown": "Nowheresville",
	"leftHanded": true,
	"feet": 5,
	"inches": 10,
	"pounds": 295,
	"years": 25
}

@export var game_stats := {
	"goals": 0, #scored goal
	"assists": 0, #passed to teammate who scored
	"sacks": 0, #stun opposing keeper
	"hits": 0, #aggressor in a collision
	"sacks_allowed": 0,#mark gets a sack
	"pitches_played": 0, #number of plays on field
	"pitches_thrown": 0,
	"aces": 0, #goals directly off pitch
	"knockouts": 0, #knocked out opposing pitcher
	"goals_for":0, #team scored while on field
	"goals_against":0 #team scored against while on field
}

#TODO: update for different parts of strategy
#TODO: import from team.gd
@export var team_strategy := {
	"shoot": 30, #keeper strategies
	"pass": 20,
	"miss": 10,
	"bull_rush": 10,
	"skill_rush": 10,
	"target_man": 10,
	"shooter": 25,
	"rebound": 5,
	"pick": 10,
	"bully": 35
}

@export var fencing_params := {
	"ideal_distance": 12.0,
	"advance_speed": attributes.speed * 0.75,
	"retreat_speed": attributes.speed,
	"attack_cooldown": 1.0,
	"ball_proximity_threshold": 45
}

#character appearance. paths to assets
var portrait: String = "res://Assets/Player Portraits/placeholder portrait.png"
var head: String
var haircut: String
var glove: String
var shoe: String
var body_type: int

#universal fields
var current_behavior: String #used for state machine

#in-match combat
var attack_target: Player = null
var current_opponent: Player = null
var fencing_timer: float = 0.0
var attack_cooldown: float = 0.0
const dodge_factor: float = 1.2
var is_dodging: bool = false
var is_juking:bool = false #true if using juke, false if using roll
var is_clockwise:bool = false
var dodge_phase: int = 0#juke has 2 phases
var current_dodge_frame: int = 0
var dodge_frames: int = 30
var dodge_direction: Vector2
#keeper only, but in this class because that's where collision is
var special_ability: String #determines which of the 
var is_anchor: bool = false #halves impact against in collisions
var is_tireless: bool = false #infinite boost
var is_maestro: bool = false #slows down time


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

#debugging
var debug: bool = false
var debug_frames: int = 20
var current_debug_frame:int = 0


# Energy Systems
@export var max_energy: float = 100.0

#movement
var plays_left_side: bool = false
var current_sprint_target
var current_sprint_curve
var ball #every player knows about the ball
var can_move: bool = true
const toss_factor: float = 0.75
var assigned_half: Area2D

# State Tracking
var is_controlling_player: bool = false
var is_sprinting: bool = false
var is_spinning: bool = false
var is_stunned: bool = false
var is_incapacitated: bool = false
var is_in_brawl: bool = false
var team: int = 1
var position_type: String = ""
var overall_state
var behaviors: Array #lists all possible child type behaviors


# Brawl Variables
var brawl_attack_power: float = 0.0
var brawl_defense: float = 0.0
var brawl_health: float = 0.0
var brawl_opponents: Array = []

# Nodes TODO
var stamina_bar
var boost_bar
var state_label
@onready var stun_timer = $StunTimer
@onready var spin_cooldown = $SpinCooldown
@onready var label = $RichTextLabel
@onready var aim_target: AimTarget
@onready var aim: Vector2 #will be either aim_target's position or a Vector2 depending on AI/human control

#position tracking
var fieldType: String = "road"
var fieldHeight: float = 0.0
var returnSpeed: float = 12


func _ready():
	collision_layer = 0b0100  # Layer 3 (players)
	collision_mask = 0b0011  # Collide with obstacles (2) and balls (1)
	$AttackArea.body_entered.connect(_on_attack_area_body_entered)
	$AttackArea.collision_mask = 0b0100  # Detect other players (layer 3)
	$AttackArea.collision_layer = 0b0100  # Be detected by other players (layer 3)
	status.energy = max_energy
	status.max_boost = status.energy * (attributes.endurance/100)
	status.boost = status.max_boost
	status.stability = attributes.endurance
	status.groove = 0#start the game with no groove
	fencing_params.ball_proximity_threshold = attributes.reactions/2
	update_ui()

func _physics_process(delta):
	if !can_move:
		velocity = Vector2.ZERO
		return

	if is_incapacitated:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_stunned:
		handle_stun_movement(delta)
		move_and_slide()
		return
			
		
	if is_dodging:
		execute_dodging()
		move_and_slide()
		return
				
	
	if is_controlling_player:
		if can_move:
			handle_human_input(delta)
	else:
		handle_ai_input()
	
	if is_sprinting:
		status.boost = status.boost -0.25
		
	if is_tireless:
		status.energy = 100
		status.boost = status.max_boost
	# Energy/boost recovery
	if not is_sprinting:
		recover_resources()
	
	move_and_slide()
	update_ui()

func handle_human_input(delta):
	# Movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	
	# Sprinting
	if Input.is_action_pressed("sprint") and status.boost > 5 and not is_spinning:
		is_sprinting = true
		velocity = input_dir.normalized() * attributes.sprint_speed
	elif Input.is_action_pressed("walk"):
		is_sprinting = false
		velocity = input_dir.normalized() * attributes.speed / 2
	else:
		is_sprinting = false
		velocity = input_dir.normalized() * attributes.speed
	
	# Dodging
	if Input.is_action_just_pressed("dodge"):
		attempt_dodge()
	
	## Attacking
	#if Input.is_action_just_pressed("attack_player"):
		#if aim:
			#attempt_attack(aim)

func reset_game_stats():
	game_stats.goals = 0
	game_stats.assists = 0
	game_stats.sacks = 0
	game_stats.hits = 0
	game_stats.sacks_allowed = 0
	game_stats.pitches_played = 0
	game_stats.pitches_thrown = 0
	game_stats.aces = 0
	game_stats.knockouts = 0
	game_stats.goals_for = 0
	game_stats.goals_against = 0

func handle_ai_input():
	# To be implemented by child classes
	pass

func handle_stun_movement(delta):
	# Slow stumbling movement when stunned
	velocity = velocity.move_toward(Vector2.ZERO, delta * 200)

func recover_resources():
	status.max_boost = status.energy * (attributes.endurance/100)
	
	if status.boost > status.max_boost:
		status.boost = status.max_boost
	else:
		status.boost = status.boost + 1
	if status.stability >= attributes.balance:
		status.stability = attributes.balance
	else:
		status.stability = status.stability + 1
	# Boost recovers when not sprinting
	if is_sprinting:
		status.boost = status.boost - 1

#ai runs real fast at something, curves movement a bit
func attempt_sprint(target_position: Vector2):
	if status.boost < 1 or is_spinning:
		return
	is_sprinting = true
	
	# Calculate base direction
	var to_target = (target_position - global_position).normalized()
	var base_speed = attributes.speed * 1.8  # 80% faster than normal
	
	# Add slight initial curve (left or right)
	var curve_direction = 1 if randf() > 0.5 else -1
	var initial_curve = curve_direction * (0.5 + randf() * 0.5) * (attributes.aggression / 100.0)
	
	# Calculate variance based on confidence
	var variance = 1.0 - (attributes.confidence / 100.0)
	var random_angle = randf_range(-0.2 * variance, 0.2 * variance)
	
	# Apply initial curve and random angle
	var launch_direction = to_target.rotated(initial_curve + random_angle)
	var launch_power = base_speed * (0.9 + randf() * 0.2)  # Small speed variance
	
	# Apply the force
	velocity = launch_direction * launch_power
	
	# Visual effects
	$SprintParticles.emitting = true
	$SprintSound.play()
	
	# Start managing the curved path
	$SprintTimer.start(0.1)  # Will update curve every 0.1 seconds
	$SprintPathCurve.clear_points()
	$SprintPathCurve.add_point(global_position)
	
	# Store sprint parameters
	current_sprint_target = target_position
	current_sprint_curve = initial_curve * 0.5  # Reduce curve over time

func get_closest_point(line_start : Vector2, line_direction : Vector2, point_position : Vector2):
	line_direction = line_direction.normalized()
	var vector_to_object := point_position - line_start
	var distance := line_direction.dot(vector_to_object)
	var closest_position = line_start + distance * line_direction
	return closest_position

func attempt_dodge():
	print("dodge: " + str(status.boost))
	if status.boost < 0:
		return
	status.boost -= 1
	
	if randf() > 0.5:
		juke(Vector2.LEFT)
	else:
		juke(Vector2.RIGHT)

	#TODO: roll?
	#if !(is_dodging and is_juking) or (is_dodging and !is_juking):#default is to juke
		#if randf() > 0.5:
			#juke(Vector2.LEFT)
		#else:
			#juke(Vector2.RIGHT)
		#return
	#else: #if one or both is blocked, roll
		#var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		#var direction
		#var random = randf()
		#if random < 0.25:
			#direction = directions[0]
		#elif random < 0.5:
			#direction = directions[1]
		#elif random < 0.75:
			#direction = directions[2]
		#else:
			#direction = directions[3]
		#if randf() < 0.5:
			#roll(true, direction)
		#else:
			#roll(false, direction)

func juke(direction: Vector2):
	print("juke")
	dodge_frames = 5
	is_dodging = true
	is_juking = true
	dodge_phase = 0
	dodge_direction = direction

func roll(clockwise: bool, direction: Vector2):
	print("roll")
	is_dodging = true
	is_juking = false
	dodge_frames = 5
	dodge_phase = 0
	is_clockwise = clockwise
	dodge_direction = direction
	
func execute_dodging():
	if !is_dodging:
		return
	current_dodge_frame += 1
	
	if is_juking:
		# Juke has two phases
		if dodge_phase == 0: # First phase (fake)
			if current_dodge_frame < dodge_frames:
				velocity = dodge_direction * attributes.sprint_speed
			else:
				# Switch to second phase
				dodge_phase = 1
				current_dodge_frame = 0
				dodge_direction *= -1 # Reverse direction
				dodge_frames *= 2 # Longer movement for actual dodge
		else: # Second phase (actual dodge)
			if current_dodge_frame < dodge_frames:
				velocity = Vector2(dodge_direction.x * attributes.sprint_speed * dodge_factor, velocity.y)
			else:
				# End dodge
				is_dodging = false
				dodge_phase = 0
				current_dodge_frame = 0
				velocity = Vector2(0, velocity.y)
	else:
		# Roll has four phases
		if current_dodge_frame >= dodge_frames:
			current_dodge_frame = 0
			dodge_phase += 1
			if is_clockwise:
				dodge_direction = dodge_direction.rotated(PI/2).normalized()
			else:
				dodge_direction = dodge_direction.rotated(-PI/2).normalized()
		
		if dodge_phase < 4:
			velocity = dodge_direction * attributes.sprint_speed * dodge_factor
		else:
			# End roll
			is_dodging = false
			velocity = Vector2.ZERO



func attempt_attack(target_position: Vector2):
	if status.boost < 0:
		return
	# Start sprinting toward target
	is_sprinting = true
	status.boost -= 2
	var to_target = (target_position - global_position).normalized()
	velocity = to_target * attributes.sprint_speed
	
	# Connect the area entered signal if not already connected
	if not $AttackArea.body_entered.is_connected(_on_attack_area_body_entered):
		$AttackArea.body_entered.connect(_on_attack_area_body_entered)
	
	# Stamina cost
	status.energy -= 10
	
func _on_attack_area_body_entered(body: Node2D):
	if body != self and body is Player and body.team != team:
		print("collision detected")
		# Calculate attack power (your force toward opponent)
		var attack_dir = (body.global_position - global_position).normalized()
		var my_velocity_toward_opponent = velocity.project(attack_dir).length()
		var attackPower = my_velocity_toward_opponent * (attributes.power / 100.0)
		# Calculate opponent's attack power (their force toward you)
		var opp_attack_dir = (global_position - body.global_position).normalized()
		var opponent_velocity_toward_me = body.velocity.project(opp_attack_dir).length()
		var oppAttackPower = opponent_velocity_toward_me * (body.attributes.power / 100.0)
		# Apply bounce impulse to opponent
		if my_velocity_toward_opponent > 0:
			print("I hit you")
			body.take_hit(self, attackPower)
		if my_velocity_toward_opponent > opponent_velocity_toward_me:
			print("I am the aggressor")
			game_stats.hits += 1
		
		# Apply the hit with calculated power
		
		
		# If opponent was moving toward us, roll for durability
		if oppAttackPower > 0:
			var rand = randi_range(0, 100)
			if rand > attributes.durability: #roll failed
				rand = randi_range(0, 100) #roll again
				if rand > attributes.durability: #roll failed twice, bad luck
					#get hurt
					print("ouchie!")
					#TODO: implement injury debuffs
					#TODO: determine severity of injury debuff based on attackpower
					#TODO: apply health damage
		
		# Stop the attack sprint
		is_sprinting = false
		velocity = Vector2.ZERO
		

func take_hit(attacker: Player, power: float):
	if is_anchor:
		power = power/2
		status.stability = 100
	#print("hit taken")
	#if is_spinning:
		## Counter-attack if spinning
		#attacker.take_hit(self, power * 0.5)
		#return
	var knockback_power = power - (status.stability * attributes.power)#TODO: balance
	print("power: " + str(power)+", knockback_power: " + str(knockback_power) + ", stability: " + str(status.stability))
	if power < status.stability: #just a nudge
		status.stability = status.stability - abs(knockback_power) #but he do be stumbling
		#print("stability remaining: " + str(status.stability))
		return
	else: #big hit! more power than sta
		var stun_time = (12-attributes.toughness/10) #7 for 50 toughness, 2.1 for 99 toughness
		status.stability = 0
		enter_stunned_state(stun_time)
		#print("stunned for " + str(stun_time))
	var knockback_dir = (global_position - attacker.global_position).normalized()
	var units = power - (attributes.power/2)
	if units < 0:#big boy don't budge
		var min_distance = 12 - (attributes.power/10)
		get_tossed(knockback_dir, min_distance)
		return
	else:
		if units > 20:
			units = 20
		get_tossed(knockback_dir, units)
		
func get_tossed(direction: Vector2, units: int):
	#print("tosser " + str(units))
	velocity = velocity * toss_factor
	if units <= 0:
		return
	else:
		global_position = global_position + (direction)
		get_tossed(direction, units - 1)

func enter_stunned_state(duration: float):
	is_stunned = true
	stun_timer.start(duration)
	#$StunAnimation.play("stun")

func apply_health_damage(amount: float):
	#TODO: blood
	status.health = status.health - amount
	pass

func _on_stun_timer_timeout():
	is_stunned = false
	
func _make_combat_decision(opponent_position: Vector2, current_dist: float):
	"""Decides to attack or dodge during fencing"""
	var attack_prob = (0.4*attributes.aggression/99.0) + (0.3*(1.0 - current_dist/fencing_params["ideal_distance"]))
	
	if attack_prob > 0.65:
		attempt_attack(opponent_position)
		fencing_timer = 0.0
		velocity += (global_position - current_opponent.global_position).normalized() * 100.0
	else:
		attempt_dodge()
		fencing_timer = fencing_params["attack_cooldown"] * 0.5

func apply_opponent_stun(duration: float):
	# Implement stun logic for opponents
	pass

func update_ui():
	label.bbcode_enabled = true
	label.set_text(position_type)
	#stamina_bar.value = energy
	#boost_bar.value = boost
	#
	#if is_controlling_player:
		#state_label.text = ""
	#else:
		#state_label.text = "%s\nE:%.0f B:%.0f" % [position_type, energy, boost]
	pass

func check_is_incapacitated() -> bool:
	return is_incapacitated or is_stunned
	
func reset_state():
	#print("Energy: " + str(status.energy))
	overall_state = PlayerState.IDLE
	is_stunned = false
	is_sprinting = false
	is_incapacitated = false
	status.stability = attributes.balance
	status.max_boost = status.energy
	status.boost = status.max_boost
	
func child_state():
	overall_state = PlayerState.CHILD_STATE
	
func fighting_state():
	overall_state = PlayerState.IN_BRAWL
	
func out_fight():
	if team == 1:
		overall_state = PlayerState.OUT_BRAWL
	else:
		overall_state = PlayerState.AI_OUT_BRAWL
		
func is_in_half()->bool:
	if !assigned_half:
		return false
	else:
		var half_extents = assigned_half.get_node("CollisionShape2D").shape.extents
		var rect = Rect2(assigned_half.global_position - half_extents, half_extents * 2)
		if rect.has_point(global_position):
			return true
		else:
			return false

func move_towards_half():
	if !assigned_half:
		return
	$CollisionPolygon2D.disabled = true
	$AttackArea/CollisionPolygon2D.disabled = true
	var half_extents = assigned_half.get_node("CollisionShape2D").shape.extents
	var half_position = assigned_half.global_position
	var half_rect = Rect2(half_position - half_extents, half_extents * 2)
	var target_x = clamp(global_position.x, half_rect.position.x, half_rect.end.x)
	var target_y = clamp(global_position.y, half_rect.position.y, half_rect.end.y)
	velocity = Vector2.ZERO
	if global_position.x < half_rect.position.x:  # Too far left
		velocity.x = attributes.speed
	elif global_position.x > half_rect.end.x:     # Too far right
		velocity.x = -attributes.speed
	if global_position.y < half_rect.position.y:  # Too far up
		velocity.y = attributes.speed
	elif global_position.y > half_rect.end.y:     # Too far down
		velocity.y = -attributes.speed
	if velocity.x != 0 or velocity.y != 0:
		current_behavior = "returning"
		velocity = velocity.normalized() * attributes.speed
	if is_in_half():
		$CollisionPolygon2D.disabled = false
		$AttackArea/CollisionPolygon2D.disabled = false

#used for bending runs. If the character knows where they are moving two moves in advance,
#they can make a curved run to make that turn more natural
func calculate_turn_angle(current_dir: Vector2, next_dir: Vector2) -> float:
	return abs(current_dir.angle_to(next_dir))

func apply_turn_anticipation(base_direction: Vector2, turn_angle: float, next_waypoint: Vector2, current_waypoint: Vector2) -> Vector2:
	if turn_angle > deg_to_rad(45):
		var turn_direction = sign(base_direction.angle_to(next_waypoint.direction_to(current_waypoint)))
		var adjustment_strength = clamp((turn_angle - deg_to_rad(45)) / deg_to_rad(45), 0, 0.3)
		return base_direction.rotated(turn_direction * adjustment_strength).normalized()
	return base_direction
	
func add_groove(amount: int):
	status.groove += amount
	if status.groove > attributes.confidence:
		status.groove = attributes.confidence
		
func lose_groove(amount: int):
	status.groove -= abs(amount) #in case I forget whether I want to pass positives or negatives. Doesn't matter now
	if status.groove < 0:
		status.groove = 0

# Signals
signal player_hit(damage)
signal player_stunned(duration)
signal brawl_started(opponent)
signal brawl_ended(winner)
