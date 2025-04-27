class_name Ball
extends RigidBody2D

enum BallMode { PITCHING, FIELDING, AIR_HOCKEY }

signal caught_by_player(player: Node2D)
signal hit_by_batter(power: float)
signal entered_air_hockey_mode()
signal ball_speed(movement: Vector2)

@export_group("Physics Properties")
@export var drag_coefficient: float = 0.05
@export var spin_curve_factor: float = 0.3
@export var max_speed: float = 2000.0
@export var min_speed_air_hockey: float = 300.0

var current_mode: BallMode = BallMode.PITCHING
var current_holder: Node2D = null
var spin: float = 0.0
var initial_pitch_velocity: Vector2 = Vector2.ZERO
var air_hockey_physics: bool = false
var height: float = 0
var been_hit := false
var hit_power_vector: Vector2
var curve_force

func _ready():
	contact_monitor = true
	max_contacts_reported = 10
	#body_entered.connect(_on_body_entered)

func _physics_process(delta):
	match current_mode:
		BallMode.PITCHING:
			_process_pitching_physics(delta)
		BallMode.FIELDING:
			_process_fielding_physics(delta)
		BallMode.AIR_HOCKEY:
			_process_air_hockey_physics(delta)

	# Enforce maximum speed
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func _process_pitching_physics(delta):
	ball_speed.emit(linear_velocity)
	# Apply spin-induced curve
	position = position + linear_velocity
	if spin != 0.0:
		curve_force = Vector2(-linear_velocity.y, linear_velocity.x).normalized() * spin * spin_curve_factor
		apply_central_force(curve_force)
	
	# Apply air resistance
	#var drag_force = -linear_velocity * linear_velocity.length() * drag_coefficient
	#apply_central_force(drag_force)

func _process_fielding_physics(delta):
	# Follow the holder's position when caught
	if current_holder:
		global_position = current_holder.global_position + Vector2(0, -20)  # Offset above player

func _process_air_hockey_physics(delta):
	# Maintain minimum speed in air hockey mode
	if linear_velocity.length() < min_speed_air_hockey:
		var direction = linear_velocity.normalized() if linear_velocity.length() > 0 else Vector2.RIGHT
		linear_velocity = direction * min_speed_air_hockey
	
	# Apply simplified physics
	var drag_force = -linear_velocity * linear_velocity.length() * (drag_coefficient * 0.5)
	apply_central_force(drag_force)

func be_pitched(velocity: Vector2, ball_spin: float):
	current_mode = BallMode.PITCHING
	current_holder = null
	spin = ball_spin
	initial_pitch_velocity = velocity
	linear_velocity = velocity
	freeze = false
	print("I am be pitched " + str(linear_velocity))

func be_caught(by_player: Node2D):
	current_mode = BallMode.FIELDING
	current_holder = by_player
	linear_velocity = Vector2.ZERO
	freeze = true
	caught_by_player.emit(by_player)

func be_hit(power_vector: Vector2):
	hit_power_vector = power_vector
	been_hit = true
	current_mode = BallMode.AIR_HOCKEY
	current_holder = null
	spin = 0.0
	linear_velocity = power_vector
	freeze = false
	hit_by_batter.emit(power_vector.length())
	entered_air_hockey_mode.emit()

func be_passed(target_position: Vector2, power: float):
	if current_mode != BallMode.FIELDING or not current_holder:
		return
	
	current_mode = BallMode.PITCHING
	current_holder = null
	freeze = false
	
	var direction = (target_position - global_position).normalized()
	linear_velocity = direction * power
	spin = power * 0.05 * (1.0 if randf() > 0.5 else -1.0)

func _on_body_entered(body: Node):
	# Handle collisions based on current mode
	match current_mode:
		BallMode.PITCHING:
			if body is Catcher:
				be_caught(body)
			elif body is Batter:
				if body.is_swinging:
					be_hit(-linear_velocity * 1.5)  # Basic hit reflection
		
		BallMode.AIR_HOCKEY:
			#TODO: goals
			#TODO: out of bounds
			#if body is GoalArea:
				#_score_goal(body.team)
				#el
			if body is Player:
				# Basic bounce physics
				var bounce_direction = (global_position - body.global_position).normalized()
				linear_velocity = bounce_direction * linear_velocity.length() * 0.9

func _score_goal(team: int):
	# Handle goal scoring
	queue_free()  # Or respawn at pitcher
	print("Goal scored by team ", team)
	
func _score_td(team:int):
	#handle td scoring
	queue_free()  # Or respawn at pitcher
	print("TD scored by team ", team)

func enter_air_hockey_mode():
	current_mode = BallMode.AIR_HOCKEY
	air_hockey_physics = true
	entered_air_hockey_mode.emit()

func _integrate_forces(state):
	# Special handling for air hockey bounces
	if air_hockey_physics:
		for i in range(state.get_contact_count()):
			var normal = state.get_contact_local_normal(i)
			state.linear_velocity = state.linear_velocity.bounce(normal) * 0.9


func _on_pitcher_ball_pitched(power: float, spin: float, direction: Vector2, position: Vector2) -> void:
	print("whoosh!")
	position = position
	var vector = direction * power
	be_pitched(vector, spin)
	pass # Replace with function body.
