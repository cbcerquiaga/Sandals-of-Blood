class_name Batter
extends BallPlayer

enum Handedness { LEFT, RIGHT, SWITCH }
enum SwingType { CONTACT, POWER, BUNT }
enum State { DEFAULT, WINDUP, SWINGING, BUNTING }

@export var handedness: Handedness = Handedness.RIGHT
@export var bat_scene: PackedScene

var swing_type: SwingType
var bat_instance: Bat
var swing_power: float = 0.0
var swing_direction: Vector2 = Vector2.RIGHT
var batting_state

# Movement boundaries
@export var movement_boundary: Rect2 = Rect2(-100, -50, 200, 100)

func _ready():
	super._ready()
	spawn_bat()
	set_handedness(handedness)

func spawn_bat():
	if bat_scene:
		bat_instance = bat_scene.instantiate()
		add_child(bat_instance)
		bat_instance.set_batter(self)

func set_handedness(new_handedness: Handedness):
	handedness = new_handedness
	match handedness:
		Handedness.LEFT:
			swing_direction = Vector2.LEFT
			if bat_instance:
				bat_instance.position.x = -abs(bat_instance.position.x)
		Handedness.RIGHT:
			swing_direction = Vector2.RIGHT
			if bat_instance:
				bat_instance.position.x = abs(bat_instance.position.x)
		Handedness.SWITCH:
			# Default to right but can be changed
			swing_direction = Vector2.RIGHT
			if bat_instance:
				bat_instance.position.x = abs(bat_instance.position.x)

func _physics_process(delta):
	match batting_state:
		State.DEFAULT:
			handle_movement()
			handle_swing_input()
		State.WINDUP:
			windup_swing(delta)
		State.SWINGING:
			execute_swing(delta)
		State.BUNTING:
			hold_bunt()

func handle_movement():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	velocity = input_vector.normalized() * speed
	move_and_slide()
	
	# Clamp position to boundaries
	var new_position = position + velocity * get_physics_process_delta_time()
	new_position.x = clamp(new_position.x, movement_boundary.position.x, movement_boundary.end.x)
	new_position.y = clamp(new_position.y, movement_boundary.position.y, movement_boundary.end.y)
	position = new_position

func handle_swing_input():
	if Input.is_action_just_pressed("swing_contact"):
		start_swing(SwingType.CONTACT)
	elif Input.is_action_just_pressed("swing_power"):
		start_swing(SwingType.POWER)
	elif Input.is_action_just_pressed("swing_bunt"):
		start_swing(SwingType.BUNT)

func start_swing(type: SwingType):
	swing_type = type
	match type:
		SwingType.CONTACT:
			batting_state = State.SWINGING
			swing_power = 0.7 + 0.3 * power # Base power + power stat influence
		SwingType.POWER:
			batting_state = State.WINDUP
			swing_power = 0.0
		SwingType.BUNT:
			batting_state = State.BUNTING
			swing_power = 0.3 # Weak hit

func windup_swing(delta: float):
	# Wind up the swing (pull bat back)
	swing_power = min(swing_power + delta * (0.5 + power * 0.5), 1.0)
	
	if swing_power >= 1.0 or Input.is_action_just_released("swing_power"):
		batting_state = State.SWINGING

func execute_swing(delta: float):
	if not bat_instance:
		batting_state = State.DEFAULT
		return
	
	# Animate the bat swing
	var swing_speed = 10.0 * (0.8 + power * 0.4) * swing_power
	bat_instance.swing(swing_direction, swing_speed, delta)
	
	# Check if swing is complete
	if bat_instance.is_swing_complete():
		batting_state = State.DEFAULT

func hold_bunt():
	if not bat_instance:
		batting_state = State.DEFAULT
		return
	
	bat_instance.bunt_position()
	
	if Input.is_action_just_released("swing_bunt"):
		batting_state = State.DEFAULT

func calculate_hit_effect(hit_position: Vector2, ball: RigidBody2D) -> Vector2:
	# Calculate the effect of the hit based on bat position, batter stats, and ball properties
	var hit_power = swing_power * power
	
	# Random chance to whiff based on focus
	if randf() > focus * 0.9: # Higher focus = lower whiff chance
		return Vector2.ZERO # Whiff - no contact
	
	# Calculate direction variance based on control
	var direction_variance = (1.0 - control) * 30.0 # Degrees of variance
	var random_angle = deg_to_rad(randf_range(-direction_variance, direction_variance))
	var base_direction = swing_direction.rotated(random_angle)
	
	# Calculate speed based on hit power and sweet spot
	var hit_speed = ball.linear_velocity.length() * 0.5 + hit_power * 1200.0
	
	# Apply curve effect from the ball
	var curve_effect = ball.curve_force * 50.0 if "curve_force" in ball else 0.0
	var final_direction = base_direction.rotated(deg_to_rad(curve_effect))
	
	return final_direction * hit_speed
