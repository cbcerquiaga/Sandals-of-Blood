extends CharacterBody2D
class_name Player

# Player Attributes
@export var attributes := {
	"speed": 300.0,
	"sprint_speed": 400.0,
	"aggression": 50, #1-100, impacts decision making
	"reactions": 90, #1-100, impacts AI speed
	"durability": 75,	#1-100, impacts injury chance
	"power": 70,        # 1-100, affects hit strength
	"endurance": 60,    # 1-100, affects boost recovery and maximum boost
	"accuracy": 65,     # 1-100, affects shot precision  
	"balance": 55,		# 1-100, affects damage taken from hits
	"focus": 50,        # 1-100, affects curve control
	"shooting": 50,		# 1-100, affects shot and pass speed for forwards
	"fight": 40,        # 1-100, brawl attack power
	"toughness": 60,    # 1-100, brawl defense
	"confidence": 50    # 1-100, affects special moves
}

@export var status := {
	"energy": 100, #long-term endurance that depletes every pitch, also used for fighting
	"health": 100, #used for injuries
	"boost": 100, #short-term endurance that applies to sprinting and dodging, recovers immediately
	"max_energy": 100, #always 100
	"max_boost": 100#variable dependent on energy
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


# Energy Systems
@export var max_energy: float = 100.0

#moevement
var plays_left_side: bool = false
var current_sprint_target
var current_sprint_curve
var ball #every player knows about the ball
var can_move: bool = true

# State Tracking
var is_controlling_player: bool = false
var is_sprinting: bool = false
var is_spinning: bool = false
var is_stunned: bool = false
var is_incapacitated: bool = false
var is_in_brawl: bool = false
var team: int = 1
var position_type: String = ""


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

func _ready():
	status.energy = max_energy
	status.max_boost = status.energy * (attributes.endurance/100)
	status.boost = status.max_boost
	update_ui()

func _physics_process(delta):
	if is_incapacitated:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_stunned:
		handle_stun_movement(delta)
		move_and_slide()
		return
	
	if is_in_brawl:
		handle_brawl_input()
		return
	
	if is_controlling_player:
		if can_move:
			handle_human_input(delta)
	else:
		handle_ai_input()
	
	# Energy/boost recovery
	if not is_sprinting:
		recover_resources(delta)
	
	move_and_slide()
	update_ui()

func handle_human_input(delta):
	# Movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_speed = attributes.speed * (1.0 + (status.boost / 200.0)) if is_sprinting else attributes.speed
	
	velocity = input_dir.normalized() * move_speed
	
	# Sprinting
	if Input.is_action_pressed("sprint") and status.boost > 5 and not is_spinning:
		is_sprinting = true
		status.boost -= delta * 20
	else:
		is_sprinting = false
	
	# Spinning
	if Input.is_action_just_pressed("dodge") and not is_sprinting and status.boost > 15 and spin_cooldown.is_stopped():
		start_spin()
	
	# Attacking
	if Input.is_action_just_pressed("attack") and not is_spinning:
		attempt_attack()
	
	# Special moves (position-specific)
	#if position_type == "pitcher" and is_controlling_player:
		#handle_pitcher_input()

func handle_ai_input():
	# To be implemented by child classes
	pass

func handle_stun_movement(delta):
	# Slow stumbling movement when stunned
	velocity = velocity.move_toward(Vector2.ZERO, delta * 200)

func recover_resources(delta):
	# Energy recovers slowly all the time
	status.energy = min(status.energy + delta * (0.5 + attributes.endurance * 0.01), max_energy)
	status.max_boost = status.energy * (attributes.endurance/100)
	# Boost recovers when not sprinting
	if not is_sprinting:
		status.boost = min(status.boost + delta * (10 + attributes.endurance * 0.2), status.max_boost)

#ai runs real fast at something, curves movement a bit
func attempt_sprint(target_position: Vector2):
	if status.boost < 20 or is_spinning:
		return
	
	# Start sprinting
	is_sprinting = true
	status.boost -= 20
	
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

func _on_sprint_timer_timeout():
	if not is_sprinting:
		return
	
	# Update current curve (decaying over time)
	current_sprint_curve *= 0.8
	
	# Recalculate direction with current curve
	var to_target = (current_sprint_target - global_position).normalized()
	velocity = velocity.lerp(to_target.rotated(current_sprint_curve) * velocity.length(), 0.1)
	
	# Add some random variance during sprint
	var variance = 1.0 - (attributes.confidence / 100.0)
	if randf() < 0.3:  # 30% chance to adjust per tick
		velocity = velocity.rotated(randf_range(-0.05 * variance, 0.05 * variance))
	
	# Record path for visualization/debugging
	$SprintPathCurve.add_point(global_position)
	
	# Continue sprint if we still have boost and aren't at target
	if status.boost > 5 and global_position.distance_to(current_sprint_target) > 50:
		status.boost -= 1  # Continuous boost drain
		$SprintTimer.start(0.1)
	else:
		end_sprint()

func end_sprint():
	is_sprinting = false
	$SprintParticles.emitting = false
	$SprintCooldown.start()
	
	# Apply slight overshoot momentum
	velocity *= 0.7  # Reduce speed but maintain direction
	

func start_spin():
	is_spinning = true
	status.boost -= 15
	spin_cooldown.start()
	
	# Visual effect
	$SpinParticles.emitting = true
	$SpinAnimation.play("spin")
	
	# Hitbox becomes intangible
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	
	await get_tree().create_timer(0.5).timeout
	is_spinning = false
	$Hitbox/CollisionShape2D.set_deferred("disabled", false)

func attempt_attack():
	if not $AttackCooldown.is_stopped():
		return
	
	$AttackCooldown.start()
	$AttackAnimation.play("attack")
	
	# Calculate attack power based on speed and attributes
	var attack_power = (velocity.length() / 500.0) * attributes.power
	
	# Check for hits in attack range
	var hit_objects = $AttackArea.get_overlapping_bodies()
	for body in hit_objects:
		if body != self and body is Player and body.team != team:
			body.take_hit(self, attack_power)
	
	# Stamina cost
	status.energy -= 10

func take_hit(attacker: Player, power: float):
	if is_spinning:
		# Counter-attack if spinning
		attacker.take_hit(self, power * 0.5)
		return
	
	# Calculate damage - split between energy, balance, and health
	var total_damage = power * (1.0 - (attributes.toughness / 200.0))
	
	# First drain energy
	var energy_damage = min(total_damage * 0.7, status.energy)
	status.energy -= energy_damage
	total_damage -= energy_damage
	
	# Then affect balance (chance to stumble)
	if total_damage > 0:
		var balance_damage = total_damage * 0.5
		var stumble_chance = balance_damage / 30.0
		if randf() < stumble_chance:
			enter_stunned_state(balance_damage)
			total_damage -= balance_damage
	
	# Any remaining damage affects health (potential injury)
	if total_damage > 0:
		apply_health_damage(total_damage)
	
	# Knockback effect
	var knockback_dir = (global_position - attacker.global_position).normalized()
	velocity = knockback_dir * power * 2

func enter_stunned_state(duration: float):
	is_stunned = true
	stun_timer.start(duration)
	$StunAnimation.play("stun")

func apply_health_damage(amount: float):
	#TODO
	pass

func _on_stun_timer_timeout():
	is_stunned = false

func start_brawl(opponent: Player):
	is_in_brawl = true
	brawl_opponents.append(opponent)
	
	# Initialize brawl stats
	brawl_attack_power = attributes.fight
	brawl_defense = attributes.toughness
	brawl_health = 30 + (attributes.toughness * 0.5)
	
	# Lock movement
	velocity = Vector2.ZERO

func handle_brawl_input():
	if not is_controlling_player:
		return
	
	# Simple brawl controls
	if Input.is_action_just_pressed("attack"):
		brawl_attack()
	elif Input.is_action_just_pressed("block"):
		brawl_block()

func brawl_attack():
	for opponent in brawl_opponents:
		var damage = brawl_attack_power * (0.8 + randf() * 0.4)
		opponent.take_brawl_damage(damage)

func take_brawl_damage(amount: float):
	var mitigated = amount * (1.0 - (brawl_defense / 100.0))
	brawl_health -= mitigated
	
	if brawl_health <= 0:
		lose_brawl()

func lose_brawl():
	is_in_brawl = false
	enter_stunned_state(3.0) # Longer stun for losing brawl
	brawl_opponents.clear()
	
func in_brawl_behavior(delta):
	# Stay engaged in brawl
	velocity = Vector2.ZERO
	#play_brawl_animation()

func out_brawl_behavior(delta, brawl_target_position):
	# Player-controlled movement to join brawl
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	velocity = input_vector.normalized() * attributes.speed * delta
	move_and_slide()
	
	# Check if reached brawl position
	if global_position.distance_to(brawl_target_position) < 20.0:
		join_brawl()
	
	# Brawl commands
	if Input.is_action_just_pressed("brawl_attack"):
		brawl_attack()
	if Input.is_action_just_pressed("brawl_block"):
		brawl_block()
		
func join_brawl():
	#in brawl instead of out brawl
		trigger_next_brawl_participant()

func trigger_next_brawl_participant():
	# Implement logic to find next closest player and set their state
	pass

func brawl_block():
	if status.energy <= 0:
		return
	
	# Calculate block effectiveness
	var block_power = attributes.toughness * 0.8
	var stun_duration = block_power * 0.5
	
	# Apply stun to opponents
	apply_opponent_stun(stun_duration)
	
	# Consume energy
	status.energy = max(0, status.energy - 10)

func apply_opponent_stun(duration: float):
	# Implement stun logic for opponents
	pass

func update_ui():
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

# Signals
signal player_hit(damage)
signal player_stunned(duration)
signal brawl_started(opponent)
signal brawl_ended(winner)
