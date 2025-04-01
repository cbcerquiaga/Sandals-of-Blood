class_name Pitcher
extends BallPlayer

## Signals
signal ball_pitched(ball: Ball)
signal pitch_started
signal pitch_parameters_changed(power: float, spin: float, direction: Vector2)

## Pitching parameters
@export_group("Pitching Controls")
@export var max_power: float = 1000.0
@export var max_spin: float = 50.0
@export var pitch_animation: String = "pitch"
@export var windup_time: float = 0.5

## Current pitch values
var current_power: float = 0.0
var current_spin: float = 0.0
var current_direction: Vector2 = Vector2.RIGHT
var is_winding_up: bool = false
var windup_timer: float = 0.0

func _physics_process(delta):
	if not can_move:
		return
	
	if is_player_controlled:
		_handle_pitch_controls()
	
	if is_winding_up:
		_process_windup(delta)
	
	super._physics_process(delta)

func _handle_pitch_controls():
	if is_winding_up:
		return
	
	# Power control (e.g., hold button to increase power)
	if Input.is_action_pressed("increase_power"):
		current_power = min(current_power + 10.0, max_power)
		emit_pitch_parameters()
	
	if Input.is_action_pressed("decrease_power"):
		current_power = max(current_power - 10.0, 0.0)
		emit_pitch_parameters()
	
	# Spin control
	if Input.is_action_pressed("increase_spin"):
		current_spin = min(current_spin + 1.0, max_spin)
		emit_pitch_parameters()
	
	if Input.is_action_pressed("decrease_spin"):
		current_spin = max(current_spin - 1.0, -max_spin)
		emit_pitch_parameters()
	
	# Direction control (aim with stick/mouse)
	var input_dir = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if input_dir.length() > 0.1:
		current_direction = input_dir.normalized()
		emit_pitch_parameters()
	
	# Initiate pitch
	if Input.is_action_just_pressed("pitch_ball") and has_ball:
		start_pitch_windup()

func emit_pitch_parameters():
	pitch_parameters_changed.emit(current_power/max_power, current_spin/max_spin, current_direction)

func start_pitch_windup():
	if not has_ball or is_winding_up:
		return
	
	is_winding_up = true
	windup_timer = windup_time
	pitch_started.emit()
	
	# TODO:Play windup animation
	#if animation_player:
		#animation_player.play(pitch_animation)

func _process_windup(delta):
	windup_timer -= delta
	
	if windup_timer <= 0.0:
		execute_pitch()
		is_winding_up = false

func execute_pitch():
	if not has_ball:
		return
	
	# Calculate final pitch vector
	var pitch_velocity = current_direction * current_power
	
	# Release the ball with calculated parameters
	var pitched_ball = ball
	release_ball()
	pitched_ball.be_pitched(pitch_velocity, current_spin)
	
	# Reset pitch parameters
	current_power = 0.0
	current_spin = 0.0
	
	# Emit the pitched event
	ball_pitched.emit(pitched_ball)
	
	# Allow all players to move
	on_ball_pitched()

func set_auto_pitch(target: Vector2, power_percent: float = 0.7, spin_percent: float = 0.3):
	if not has_ball:
		return
	
	current_direction = (target - global_position).normalized()
	current_power = max_power * power_percent
	current_spin = max_spin * spin_percent * (1.0 if randf() > 0.5 else -1.0)
	start_pitch_windup()

func _on_animation_finished(anim_name):
	if anim_name == pitch_animation and is_winding_up:
		# In case animation ends before timer
		execute_pitch()
		is_winding_up = false
