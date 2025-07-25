extends CharacterBody2D
class_name Player

var playable_positions = ["LG, RG, LF, RF, K, P"]#players can train to be more versatile and play more positions
var declared_pitcher = false #affects roster size rules
var field_position: String
# Player Attributes
@export var attributes := {
	"speedRating" : 75, #what's shown on the attributes screen
	"speed": 110.0, #actual move speed, speedRating+35
	"sprint_speed": 140.0, #max speed, (speedRating-5 * 2)
	"blocking": 50, #shot blocking skill
	"positioning" : 90, #player's positioning ability
	"aggression": 50, #1-100, impacts decision making
	"reactions": 90, #1-100, impacts AI speed
	"durability": 75,	#1-100, impacts injury chance
	"power": 70,        # 1-100, affects hit strength, pitch power
	"throwing": 75, #1-100, modifies power when throwing
	"endurance": 60,    # 1-100, affects boost recovery and maximum boost
	"accuracy": 65,     # 1-100, affects shot precision and pitch accuracy
	"balance": 55,		# 1-100, affects damage taken from hits and stability in fights
	"focus": 50,        # 1-100, affects curve control
	"shooting": 50,		# 1-100, affects shot and pass speed, punch power in fights
	"toughness": 60,    # 1-100, fighting defense/skill
	"confidence": 90    # 1-100, affects special moves
}

@export var status := {
	"momentum": 0,#builds up as the player moves
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

#if the player is playing forward
var forward_strategy = {
	"bull_rush": 50.0,
	"skill_rush": 100.0,
	"target_man": 100.0,
	"shooter": 100.0,
	"rebound": 50.0,
	"pick": 10.0,
	"bully": 10.0,
	"fencing": 5.0,
	"cower": 5.0
}

#if the player is playing guard
var defense_strategy = {
	"marking": 0.7,  # 0-1, likelihood to stay with mark (replaces discipline)
	"fluidity": 0.6,  # 0-1, preference to switch forwards on a pick, preference to fill in for keeper
	"zone": true,  # true or false, whether to play zone or man
	"lg_trap": false, #in a zone, if the LG will trap. if false, RG plays gk
	"rg_trap": true,#in a zone, if the RG will trap. if false, RG plays gk
	"chasing": 0.1,  # 0-inf, likelihood to chase loose balls
	"goal_defense_threshold": 35,  # Distance at which keeper is considered out of position
	"escort_distance": 10#how closely an escorting guard will follow the keeper
}

#character appearance. paths to assets
@onready var portrait: String = "res://Assets/Player Portraits/placeholder portrait.png"
@onready var head: String
@onready var haircut: String
@onready var glove: String
@onready var shoe: String
@onready var body_type: String
@onready var skin_tone_primary: String
@onready var skin_tone_secondary: String
@onready var complexion: String

#universal fields
var current_behavior: String #used for state machine
var needs_go_home: bool = false #overrides current behavior when stunned and out of bounds
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
var active_buffs: Dictionary = {}


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

# Signals
signal player_hit(damage)
signal player_stunned(duration)
signal brawl_started(opponent)
signal brawl_ended(winner)


func _ready():
	collision_layer = 0b0100  # Layer 3 (players)
	collision_mask = 0b0111  # Collide withplayers (3) obstacles (2) and balls (1)
	stun_timer.timeout.connect(_on_stun_timer_timeout)
	$AttackArea.body_entered.connect(_on_attack_area_body_entered)
	$AttackArea.collision_mask = 0b0100  # Detect other players (layer 3)
	$AttackArea.collision_layer = 0b0100  # Be detected by other players (layer 3)
	status.energy = max_energy
	status.max_boost = attributes.endurance * (status.energy/100)
	status.boost = status.max_boost
	status.stability = attributes.endurance
	status.groove = 0#start the game with no groove
	fencing_params.ball_proximity_threshold = attributes.reactions/2
	update_ui()

func _physics_process(delta):
	if velocity.length() > 0:
		status.momentum += 1
		if status.momentum > 100 :
			status.momentum = 100
	else:
		status.momentum = 0
	if !can_move:
		velocity = Vector2.ZERO
		return
	elif needs_go_home and assigned_half:
		print("ET Go HOOME")
		var direction = global_position.direction_to(assigned_half.global_position)
		velocity = velocity + direction.normalized() * attributes.sprint_speed * 1.1
		return
		

	if is_incapacitated:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_stunned:
		handle_stun_movement(delta)
		move_and_slide()
		status.stability = attributes.balance #re-set to 100% after being knocked over
		return
		
	if status.stability <0:
		status.stability = 0
	elif status.stability > attributes.balance:
		status.stability = attributes.balance
	
	if status.boost < 0:
		status.boost = 0
	elif status.boost > status.max_boost:
		status.boost = status.max_boost
			
		
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
		status.max_boost = attributes.endurance * (status.energy/100)
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
	if !is_in_half() and can_move:
		print("go home, player!")
		if fieldType == "road" or fieldType == "wideRoad":
			if velocity.y <= 0:
				velocity.y = 0
		
	
	# Dodging
	if Input.is_action_just_pressed("dodge"):
		attempt_dodge()
	


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
	status.max_boost = attributes.endurance * (status.energy/100)
	
	if status.boost > status.max_boost:
		status.boost = status.max_boost
	else:
		status.boost = status.boost + 2
	if status.stability >= attributes.balance:
		status.stability = attributes.balance
	else:
		status.stability = status.stability + 0.25

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
	#print("dodge: " + str(status.boost))
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
	status.boost -= 10
	
func _on_attack_area_body_entered(body: Node2D):
	if body != self and body is Player and body.team != team:
		if body.position_type == "pitcher" and position_type == "pitcher":
			current_behavior = "fighting"
			print("why I oughta")
			return
		#print("collision detected")
		# Calculate attack power (your force toward opponent)
		var attack_dir = (body.global_position - global_position).normalized()
		var my_velocity_toward_opponent = velocity.project(attack_dir).length()
		var attackPower = my_velocity_toward_opponent * (attributes.power / 100.0)
		# Calculate opponent's attack power (their force toward you)
		var opp_attack_dir = (global_position - body.global_position).normalized()
		var opponent_velocity_toward_me = body.velocity.project(opp_attack_dir).length()
		var oppAttackPower = opponent_velocity_toward_me * (body.attributes.power / 100.0)
		#momentum mechanic
		var combined_momentum = status.momentum + body.status.momentum
		if combined_momentum < 25:
			scrum(body)
			return
		# Apply bounce impulse to opponent
		body.take_hit(self, attackPower)
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
	elif  body != self and body is Player and body.team == team:
		var combined_momentum = status.momentum + body.status.momentum
		if combined_momentum < 25:
			scrum(body)
			return
			

func scrum(body: Player):
	var intended_velocity: Vector2 = Vector2.ZERO
	var opp_intended_velocity: Vector2 = Vector2.ZERO
	if is_controlling_player:
		intended_velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		var nav = $NavigationAgent2D
		intended_velocity = global_position.direction_to(nav.target_position).normalized()
	if body.is_controlling_player:
		opp_intended_velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		var nav = body.get_node("NavigationAgent2D")
		opp_intended_velocity = body.global_position.direction_to(nav.target_position).normalized()
	var scrumming_axis = (body.global_position - global_position).normalized()
	#only movement towards the opponent really matters for this
	var my_push = intended_velocity.project(scrumming_axis).length() * sign(intended_velocity.dot(scrumming_axis))
	var opp_push = opp_intended_velocity.project(-scrumming_axis).length() * sign(opp_intended_velocity.dot(-scrumming_axis))
	var my_power = (my_push * status.momentum * attributes.power) / 100.0
	var opp_power = (opp_push * body.status.momentum * body.attributes.power) / 100.0
	var power_diff = my_power - opp_power
	
	# someone who steps away gets tossed. Somebody who steps sideways or holds ground (push of 0) just gets pushed
	if opp_push < 0 and my_push > 0:
		print("come on, man")
		body.get_tossed(scrumming_axis, int(my_power/10), my_power * 10)
		return
	# If I'm not pushing but opponent has momentum, I get tossed
	elif my_push < 0 and opp_push > 0:
		get_tossed(-scrumming_axis, int(opp_power/10), opp_power * 10)
		return
	
	# Apply slow movement based on power difference
	if power_diff > 0:  # I'm stronger
		var move_amount = my_push * 10
		velocity = scrumming_axis * move_amount
		body.velocity = scrumming_axis * move_amount * 1.1  # Opponent moves slightly more
	elif power_diff < 0:  # Opponent is stronger
		var move_amount =  body.status.momentum/10
		velocity = -scrumming_axis * move_amount * 1.1
		body.velocity = -scrumming_axis * move_amount
	else:  #nobody move
		velocity = Vector2.ZERO
		body.velocity = Vector2.ZERO
	#shit is tiring
	var exhaust = 0.1
	lose_boost(exhaust)
	body.lose_boost(exhaust)
	# Small stability loss for both players
	var stability_loss = 0.5
	lose_stability(stability_loss)
	body.lose_stability(stability_loss)
	print("we scrumming. my push: ", my_push, " your push: ", opp_push)
	

func take_hit(attacker: Player, power: float):
	if is_anchor:
		power = power/5
		status.stability = 100
	#print("hit taken")
	var knockback_dir = (global_position - attacker.global_position).normalized()
	var knockback_power = abs(power * 2) - (status.stability + attributes.power)
	#if attacker.is_sprinting:
		#knockback_power *= 1.5
	if velocity.length() == 0:
		knockback_power *= 1.5
	var units = power - (attributes.power/2)
	if units > 30:
		units = 30
	#print("power: " + str(power)+", knockback: " + str(knockback_power) + ", stability: " + str(status.stability), " my power: ", attributes.power, " units: ", units)
	if knockback_power > status.stability * 2: #big hit!
		print("big hit-", units, ", ", knockback_power * 2)
		get_tossed(knockback_dir, units, 200)
		attacker.game_stats.hits += 1
		status.stability = 0
		var stun_time = (445 - 4*attributes.toughness)/49 * 0.75 #3.35 for 50 toughness, 0.675 for 99 toughness
		enter_stunned_state(stun_time)
	elif knockback_power > status.stability: #hefty bump
		print("bump-", units, ", ", 150)
		status.stability -= knockback_power/2
		if status.stability < 0:
			if attacker.team != team:
				attacker.game_stats.hits += 1
				if position_type == "keeper":
					attacker.game_stats.sacks +=1
			status.stability = 0
			var stun_time = (445 - 4*attributes.toughness)/49 * 0.75 #3.35 for 50 toughness, 0.675 for 99 toughness
			enter_stunned_state(stun_time)
		get_tossed(knockback_dir, units, knockback_power * 2)
	elif knockback_power > 0: #shove
		print("shove-", units, ", ", knockback_power * 2)
		status.stability = status.stability - knockback_power
		get_tossed(knockback_dir, units, 100)
	else: #just a step back
		scrum(attacker)
		
func get_tossed(direction: Vector2, units: int, speed: float):
	#print("tosser " + str(units))
	var nav = $NavigationAgent2D
	nav.target_position = global_position + direction.normalized() * units
	velocity = direction * speed
	if units <= 0:
		return

func enter_stunned_state(duration: float):
	is_stunned = true
	if position_type == "keeper":
		print("stunned for ", duration)
	stun_timer.start(duration)
	#$StunAnimation.play("stun")

func apply_health_damage(amount: float):
	#TODO: blood
	status.health = status.health - amount
	pass

func _on_stun_timer_timeout():
	if position_type == "keeper":
		print("should be able to move now")
	is_stunned = false
	
func _make_combat_decision(opponent_position: Vector2, current_dist: float):
	
	var attack_prob = randf()
	
	if attack_prob < attributes.aggression:
		attempt_attack(opponent_position)
		fencing_timer = 0.0
		velocity = (global_position - current_opponent.global_position).normalized() * attributes.sprint_speed
		status.momentum += 10
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
	status.max_boost = status.energy * attributes.endurance/100
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
		return true #assume they're in the right place, don't mess with them
	else:
		var half_extents = assigned_half.get_node("CollisionShape2D").shape.extents
		half_extents = half_extents * 2 #add buffer
		var rect = Rect2(assigned_half.global_position - half_extents, half_extents * 2)
		#print("rect: ", rect, " position: ", global_position)
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
	
func add_energy(amount: int):
	status.energy += amount
	if status.energy > 100:
		status.energy = 100
	
func add_groove(amount: int):
	status.groove += amount
	if status.groove > attributes.confidence:
		status.groove = attributes.confidence
		
func lose_groove(amount: int):
	status.groove -= abs(amount) #in case I forget whether I want to pass positives or negatives. Doesn't matter now
	if status.groove < 0:
		status.groove = 0
		
func lose_stability(amount: float):
	status.stability -= abs(amount) #in case I forget whether I want to pass positives or negatives. Doesn't matter now
	if status.stability < 0:
		status.stability = 0
		
func lose_energy(amount: float):
	status.energy -= abs(amount) #in case I forget whether I want to pass positives or negatives. Doesn't matter now
	if status.energy < 0:
		status.energy = 0
	status.max_boost = status.energy
	if status.boost > status.max_boost:
		status.boost = status.max_boost
		
func lose_boost(amount: float):
	status.boost -= abs(amount)
	if status.boost < 0:
		status.boost = 0

func set_default_groove():
	status.groove = int(attributes.confidence/4)
	
func get_socked(impact: float):
	if impact < 0:
		print("you are pathetic")
		return
	var impact_sqrt = sqrt(impact) 
	var num_injury_rolls = int(impact_sqrt) #vaguely between 1 and 18
	var roll
	for i in range(0, num_injury_rolls):
		roll = randf()
		if roll > attributes.durability/100.0: #not looking good
			roll = randf()
			if roll > attributes.durability/100.0:#taking some kind of injury here
				print("injury acquired on roll ", i, " of ", num_injury_rolls)

func export_to_dict() -> Dictionary:
	return {
		"attributes": attributes.duplicate(true),
		"status": status.duplicate(true),
		"bio": bio.duplicate(true),
		"game_stats": game_stats.duplicate(true),
		"position_type": position_type,
		"special_ability": special_ability,
		"portrait": portrait,
		"head": head,
		"haircut": haircut,
		"glove": glove,
		"shoe": shoe,
		"body_type": body_type,
		"skin_tone_primary": skin_tone_primary,
		"skin_tone_secondary": skin_tone_secondary,
		"complexion": complexion
	}

func import_from_dict(data: Dictionary):
	attributes = data["attributes"].duplicate(true)
	status = data["status"].duplicate(true)
	bio = data["bio"].duplicate(true)
	game_stats = data["game_stats"].duplicate(true)
	position_type = data["position_type"]
	special_ability = data["special_ability"]
	portrait = data["portrait"]
	head = data["head"]
	haircut = data["haircut"]
	glove = data["glove"]
	shoe = data["shoe"]
	body_type = data["body_type"]
	skin_tone_primary = data["skin_tone_primary"]
	skin_tone_secondary = data["skin_tone_secondary"]
	complexion = data["complexion"]
	
func add_buff(buff_name, modifiers):
	if active_buffs.has(buff_name):
		active_buffs[buff_name] = modifiers# If buff already exists, refresh it instead of adding again
		return
	for attribute in modifiers:
		if attributes.has(attribute):
			var original_value = attributes[attribute]
			var modified_value = original_value + modifiers[attribute]
			modified_value = clamp(modified_value, 0, 101)
			attributes[attribute] = modified_value
	active_buffs[buff_name] = modifiers

func remove_buff(buff_name: String):
	if not active_buffs.has(buff_name):
		return
	var modifiers = active_buffs[buff_name]
	for attribute in modifiers: # Reverse attribute modifications
		if attributes.has(attribute):
			var original_value = attributes[attribute] - modifiers[attribute]
			original_value = clamp(original_value, 0, 101)
			attributes[attribute] = original_value
	active_buffs.erase(buff_name)

func has_buff(buff_name: String) -> bool:
	return active_buffs.has(buff_name)
	
func get_position_class(position: String) -> GDScript:
	match position:
		"P":
			return load("res://Reworked_Pitcher.gd")
		"K":
			return load("res://Keeper.gd")
		"LG", "RG":
			return load("res://Guard.gd")
		"LF", "RF":
			return load("res://Forward.gd")
		_:
			return get_script()
			
			
#determines out of position penalties
func can_play_position(field_position: String) -> bool:
	# Pitchers must be declared, or else it uses up extra substitutions
	if field_position == "P" && !declared_pitcher:
		return false
	elif field_position != "P" && declared_pitcher:
		return false
	else:
		return field_position in playable_positions
