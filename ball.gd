extends RigidBody2D
class_name Ball

# Physics Properties
@export var base_speed: float = 500.0
var max_speed: float = 1500.0
@export var hockey_max_speed: float = 800.0
@export var pitching_max_speed: float = 1500
@export var min_bounce_speed: float = 50.0
var bounce_drag = 0.95 #how much speed ball retains when bouncing off walls
var center_influence = 0.5 #affects how close to 0,0 ball bounces when it's not sure where to go
var spin_curve_factor: float = 180.0

#special pitch stuff
var special_curves: Array[float] = []
var special_frames: Array[int] = []
var current_sp_frame: int = 0
var current_sp_index: int = 0
var special_pitch_type: String = ""

# Game State
enum BallState { WAITING, PITCHING, SPECIAL_PITCH, HOCKEY }
var current_state: BallState = BallState.WAITING
var current_spin: float = 0.0
var last_hit_by: Player = null
var special_trajectory: Curve2D
var trajectory_progress: float = 0.0
var pitcher_position: Vector2
var chill_timer: int = 0
var original_collision_mask: int = 0b0110
var field_type = "road"

const spin_drag_factor: float = 0.995

# Signals
signal goal_scored(team)
signal ball_entered_play
signal special_pitch_interrupted
signal area_entered(area: Area2D)

func _ready():
	collision_layer = 0b0001  # Layer 1 (balls)
	collision_mask = 0b0110   # Collide with obstacles (2) and players (3)
	original_collision_mask = collision_mask
	contact_monitor = true
	max_contacts_reported = 12
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	# Handle chill timer
	if chill_timer > 0:
		chill_timer -= 1
		if chill_timer == 0:
			collision_mask = original_collision_mask
	
	match current_state:
		BallState.PITCHING:
			apply_pitching_physics(delta)
		BallState.SPECIAL_PITCH:
			apply_special_pitch_physics(delta)
		BallState.HOCKEY:
			apply_hockey_physics(delta)
		BallState.WAITING:
			apply_waiting_physics()
	
	# Enforce max speed in all states
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func apply_waiting_physics():
	global_position = pitcher_position
	linear_velocity = Vector2.ZERO

func apply_pitching_physics(delta):
	if current_spin != 0.0:
		var perpendicular = linear_velocity.normalized().rotated(PI/2)
		var curve_force = perpendicular * current_spin * spin_curve_factor * delta
		apply_central_impulse(curve_force)
		current_spin = current_spin * spin_drag_factor #applies dpin drag
		force_inbounds()
		
func force_inbounds():
	#print("get in!")
	if field_type == "road":#TODO: update for different field types
		if global_position.x < -60 and linear_velocity.x < 0:
			linear_velocity.x = abs(linear_velocity.x) * 0.9
		elif global_position.x > 60 and linear_velocity.x > 0:
			linear_velocity.x = -abs(linear_velocity.x) * 0.9
		if global_position.y < -120 and linear_velocity.y < 0:
			linear_velocity.y = abs(linear_velocity.y) * 0.9
		elif global_position.y > 120 and linear_velocity.y > 0:
			linear_velocity.y = -abs(linear_velocity.y) * 0.9

func apply_special_pitch_physics(delta):
	current_sp_frame += 1
	
	# Check if we should advance to next curve
	if current_sp_index < special_frames.size() - 1:
		if current_sp_frame >= special_frames[current_sp_index]:
			current_sp_index += 1
	else:
		current_spin = 0
	
	# Apply current curve
	if current_sp_index < special_curves.size():
		current_spin = special_curves[current_sp_index]
	apply_pitching_physics(delta)

func apply_hockey_physics(delta):
	max_speed = hockey_max_speed

func _on_body_entered(body: Node):
	if body is Player:
		handle_player_collision(body)
	elif body is StaticBody2D: # Walls
		handle_wall_collision(body)

func _on_area_entered(area: Area2D):
	emit_signal("area_entered", area)

func handle_player_collision(player: Player):
	if current_state == BallState.WAITING:
		return
		
	last_hit_by = player
	
	match player.position_type:
		"keeper", "guard":
			handle_defender_collision(player)
		"forward":
			handle_forward_collision(player)
		"pitcher":
			if current_state == BallState.SPECIAL_PITCH:
				emit_signal("special_pitch_interrupted")
				enter_hockey_state()

func handle_defender_collision(player: Player):
	#print("smack me, daddy")
	var pass_target = player.aim
	# Add randomness based on accuracy
	var accuracy_offset = 1.0 - (player.attributes.accuracy / 100.0)	
	var pass_dir = (pass_target - global_position).normalized()
	pass_dir = pass_dir.rotated(randf_range(-accuracy_offset * 0.1, accuracy_offset * 0.1))
	apply_forward_hit(player, pass_dir)
	# Enter hockey state if not already
	if current_state != BallState.HOCKEY:
		enter_hockey_state()

func handle_forward_collision(forward: Player):
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
	if current_state != BallState.HOCKEY:
		enter_hockey_state()

func apply_forward_hit(forward: Player, direction: Vector2):
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
	#print("ball hit wall")
	var add_spin_effect = false
	
	if current_state == BallState.WAITING:
		return
	# Get predefined wall normal based on wall name/groups
	var wall_normal := Vector2.ZERO
	if current_state == BallState.PITCHING or current_state == BallState.SPECIAL_PITCH:
		if wall.is_in_group("front") or wall.is_in_group("back"):
			print("the ball careens off the back wall and onto the ground into play")
			current_state = BallState.HOCKEY
		if current_spin != 0:
			add_spin_effect = true
			
	
	var reverse = false
	# Check which wall was hit (assuming you've named them appropriately)
	if wall.is_in_group("left"):
		wall_normal = Vector2.RIGHT  # Bounce right when hitting left wall
	elif wall.is_in_group("right"):
		wall_normal = Vector2.LEFT   # Bounce left when hitting right wall
	elif wall.is_in_group("front"):
		#print("touched front wall")
		wall_normal = Vector2.UP     # Bounce up when hitting front wall
	elif wall.is_in_group("back"):
		#print("touched back wall")
		wall_normal = Vector2.DOWN   # Bounce down when hitting back wall
	else: #bounce backwards
		wall_normal = (global_position - wall.global_position).normalized()
	
	if add_spin_effect:
		apply_spin_bounce(wall_normal)
		return

	linear_velocity = linear_velocity.bounce(wall_normal)
	linear_velocity = linear_velocity * bounce_drag
		
		
	
	# Add spin effect from shallow angles
	var incoming_angle = linear_velocity.angle_to(wall_normal)
	if abs(incoming_angle) < PI/6: # Shallow angle
		current_spin = incoming_angle * linear_velocity.length() * 0.005

func be_pitched(huck: Vector2, curve: float):
	max_speed = pitching_max_speed
	current_state = BallState.PITCHING
	
	# Apply pitch immunity
	chill_timer = 10  # 10 frames of immunity
	collision_mask = 0b0010  # Only collide with obstacles during pitch
	
	linear_velocity = huck
	current_spin = curve
	freeze = false

func be_special_pitched(direction: Vector2, power: float, curves: Array[float], frames: Array[int], pitch_type: String):
	print("here comes a doozy")
	print("Type: ", pitch_type)
	print("Direction: ", direction)
	print("Power: ", power)
	print("Curves: ", curves)
	print("Frames: ", frames)
	current_state = BallState.SPECIAL_PITCH
	special_curves = curves
	special_frames = frames
	special_pitch_type = pitch_type
	current_sp_frame = 0
	current_sp_index = 0
	linear_velocity = direction.normalized() * power
	freeze = false
	chill_timer = 10

func enter_hockey_state():
	if current_state != BallState.HOCKEY:
		current_state = BallState.HOCKEY
		freeze = false
		emit_signal("ball_entered_play")

func reset_ball(position: Vector2):
	pitcher_position = position
	linear_velocity = Vector2.ZERO
	current_spin = 0.0
	current_state = BallState.WAITING
	last_hit_by = null
	special_trajectory = null
	freeze = true
	global_position = position
	collision_mask = original_collision_mask
	chill_timer = 0
	
func apply_drag():
	linear_velocity = linear_velocity * 0.95
	print("stop that ball!")
	
func apply_spin_bounce(wall_normal: Vector2):
	# Calculate reflection direction with spin influence
	var incoming_angle = linear_velocity.angle_to(wall_normal)
	var spin_effect = current_spin * 0.01  # Scale factor for spin effect
	var spin_influence = abs(incoming_angle) / (PI/2) # The more perpendicular the impact, the more spin affects the bounce, 0-1 based on angle
	# Combine normal bounce with spin effect
	var base_bounce = linear_velocity.bounce(wall_normal)
	var spin_adjusted = base_bounce.rotated(spin_effect * spin_influence * sign(incoming_angle))
	var speed = linear_velocity.length() * bounce_drag
	var new_velocity = spin_adjusted.normalized() * speed
	# Enforce bounds by adjusting the direction if needed
	var predicted_position = global_position + new_velocity * 0.1  # Look ahead slightly
	if field_type == "road":
		# Adjust X component if heading out of bounds horizontally
		if predicted_position.x < -60 and new_velocity.x < 0:
			new_velocity.x = abs(new_velocity.x) * 0.8  # Reverse and dampen
		elif predicted_position.x > 60 and new_velocity.x > 0:
			new_velocity.x = -abs(new_velocity.x) * 0.8  # Reverse and dampen
		# Adjust Y component if heading out of bounds vertically
		if predicted_position.y < -120 and new_velocity.y < 0:
			new_velocity.y = abs(new_velocity.y) * 0.8  # Reverse and dampen
		elif predicted_position.y > 120 and new_velocity.y > 0:
			new_velocity.y = -abs(new_velocity.y) * 0.8  # Reverse and dampen
	linear_velocity = new_velocity
	current_spin *= 0.8  # Loses 20% of spin energy per bounce
	print("Spin adjusted to keep in bounds (new vel: %s)" % linear_velocity)
