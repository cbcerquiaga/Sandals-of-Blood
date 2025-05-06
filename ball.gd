extends RigidBody2D
class_name Ball

# Physics Properties
@export var base_speed: float = 500.0
@export var max_speed: float = 1500.0
@export var speed_decay: float = 0.98
@export var min_bounce_speed: float = 100.0
@export var spin_decay: float = 0.95

# Game State
enum BallState { PITCHING, SPECIAL_PITCH, IN_PLAY }
var current_state: BallState = BallState.PITCHING
var current_curve: float = 0.0
var current_spin: float = 0.0
var last_hit_by: Player = null
var special_trajectory: Curve2D
var trajectory_progress: float = 0.0

# Nodes
@onready var collision_shape = $CollisionShape2D
@onready var trail_particles = $TrailParticles
@onready var impact_sound = $ImpactSound

signal goal_scored(team)
signal ball_entered_play
signal special_pitch_interrupted

func _ready():
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	match current_state:
		BallState.PITCHING:
			apply_pitching_physics(delta)
		BallState.SPECIAL_PITCH:
			follow_special_trajectory(delta)
		BallState.IN_PLAY:
			apply_in_play_physics(delta)
	
	update_visuals()

func apply_pitching_physics(delta):
	# Apply curve effect
	if current_curve != 0:
		linear_velocity = linear_velocity.rotated(current_curve * delta)
		current_curve *= spin_decay
	
	# Apply spin effect (affects bounce angles)
	if current_spin != 0:
		rotation += current_spin * delta
		current_spin *= spin_decay
	
	# Speed decay
	if linear_velocity.length() > min_bounce_speed:
		linear_velocity *= speed_decay
	
	# Speed limit
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func follow_special_trajectory(delta):
	if not special_trajectory:
		return
	
	trajectory_progress += delta
	var trajectory_length = special_trajectory.get_baked_length()
	var progress_ratio = trajectory_progress / (trajectory_length / base_speed)
	
	if progress_ratio >= 1.0:
		enter_play_state()
		return
	
	global_position = special_trajectory.sample_baked(trajectory_length * progress_ratio)

func apply_in_play_physics(delta):
	# Inherits normal physics plus additional spin effects
	apply_pitching_physics(delta)
	
	# Add slight randomness to movement
	if last_hit_by and is_instance_valid(last_hit_by):
		var accuracy_effect = 1.0 - (last_hit_by.attributes.accuracy / 100.0)
		linear_velocity = linear_velocity.rotated(randf_range(-accuracy_effect * 0.05, accuracy_effect * 0.05))

func _on_body_entered(body: Node):
	if body is Player:
		handle_player_collision(body)
	elif body is StaticBody2D: # Walls
		handle_wall_collision(body)
	
	#impact_sound.play()

func handle_player_collision(player: Player):
	last_hit_by = player
	
	match player.position_type:
		"keeper", "guard":
			handle_defender_collision(player)
		"forward":
			handle_forward_collision(player)
		"pitcher":
			if current_state == BallState.SPECIAL_PITCH:
				emit_signal("special_pitch_interrupted")
				enter_play_state()

func handle_defender_collision(player: Player):
	# Calculate reflection with physics
	var normal = (global_position - player.global_position).normalized()
	var incoming_angle = linear_velocity.angle_to(normal)
	var speed = linear_velocity.length()
	
	# Power boost from player
	var power_boost = 1.0 + (player.attributes.power / 100.0)
	var speed_boost = player.velocity.length() / 200.0
	
	# Apply bounce physics
	var new_velocity = linear_velocity.bounce(normal) * power_boost * (1.0 + speed_boost)
	
	# Add spin from shallow angles
	if abs(incoming_angle) < PI/6: # Shallow angle
		current_spin = incoming_angle * speed * 0.01
		new_velocity = new_velocity.rotated(sign(incoming_angle) * 0.1)
	
	# Add randomness based on accuracy
	var accuracy_offset = 1.0 - (player.attributes.accuracy / 100.0)
	new_velocity = new_velocity.rotated(randf_range(-accuracy_offset * 0.1, accuracy_offset * 0.1))
	
	linear_velocity = new_velocity
	
	# Enter play state if not already
	if current_state != BallState.IN_PLAY:
		enter_play_state()

func handle_forward_collision(forward: Forward):
	var goal_pos = forward.goal_position
	
	# Check if forward wants to pass
	if forward.is_in_pass_mode and forward.forward_partner:
		# Pass to partner
		var pass_target = forward.forward_partner.global_position
		var pass_dir = (pass_target - global_position).normalized()
		apply_forward_hit(forward, pass_dir)
	else:
		# Shoot at goal
		var shot_dir = (goal_pos - global_position).normalized()
		apply_forward_hit(forward, shot_dir)
	
	enter_play_state()

func apply_forward_hit(forward: Forward, direction: Vector2):
	# Calculate power - combination of shooting skill and movement
	var forward_speed_toward_goal = forward.velocity.dot(direction)
	forward_speed_toward_goal = max(0, forward_speed_toward_goal)
	
	var ball_speed_component = linear_velocity.dot(direction)
	ball_speed_component = max(0, ball_speed_component)
	
	var combined_power = (
		forward_speed_toward_goal * 0.7 + 
		ball_speed_component * 0.3
	) * (1.0 + forward.attributes.shooting / 100.0)
	
	# Apply accuracy variance
	var accuracy_offset = 1.0 - (forward.attributes.accuracy / 100.0)
	direction = direction.rotated(randf_range(-accuracy_offset * 0.2, accuracy_offset * 0.2))
	
	# Calculate final velocity
	var min_power = base_speed * 0.8
	var max_power = base_speed * 3.0
	var final_power = clamp(combined_power, min_power, max_power)
	
	linear_velocity = direction * final_power

func handle_wall_collision(wall: StaticBody2D):
	# Get wall normal (assuming walls have consistent orientation)
	var wall_normal = (global_position - wall.global_position).normalized()
	
	# Standard bounce physics
	linear_velocity = linear_velocity.bounce(wall_normal)
	
	# Add spin effect from shallow angles
	var incoming_angle = linear_velocity.angle_to(wall_normal)
	if abs(incoming_angle) < PI/6: # Shallow angle
		current_spin = incoming_angle * linear_velocity.length() * 0.005
	
	# Enter play state if not already
	if current_state != BallState.IN_PLAY:
		enter_play_state()

func set_special_trajectory(trajectory: Curve2D):
	special_trajectory = trajectory
	current_state = BallState.SPECIAL_PITCH
	trajectory_progress = 0.0
	freeze = true

func enter_play_state():
	if current_state != BallState.IN_PLAY:
		current_state = BallState.IN_PLAY
		freeze = false
		emit_signal("ball_entered_play")

func reset_ball(position):
	linear_velocity = Vector2.ZERO
	current_curve = 0.0
	current_spin = 0.0
	current_state = BallState.PITCHING
	last_hit_by = null
	special_trajectory = null
	freeze = true
	global_position = position

func update_visuals():
	# Trail intensity based on speed
	var speed_ratio = linear_velocity.length() / max_speed
	#trail_particles.process_material.emission_scale = speed_ratio
	
	# Trail color based on last hitter
	#if last_hit_by:
		#trail_particles.modulate = last_hit_by.team_color
	#else:
		#trail_particles.modulate = Color.WHITE
