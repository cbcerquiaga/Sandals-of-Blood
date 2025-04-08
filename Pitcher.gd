class_name Pitcher
extends BallPlayer

## Signals
signal ball_pitched(power: float, spin: float, direction: Vector2, position: Vector2)
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
var min_power := 400
var power_increment := 10
var increasing := true
var active := false
var power_timer : Timer

func _physics_process(delta):
	if not can_move:
		return
	
	if is_player_controlled:
		_handle_pitch_controls()
		if (is_winding_up):
			_process_windup()
			if Input.is_action_just_pressed("pitch"):
				print("huck that sucka")
				ball_pitched.emit(current_power, current_spin, current_direction, position)
	
	if is_winding_up:
		_process_windup()
	
	super._physics_process(delta)

func _handle_pitch_controls():
	if is_winding_up:
		return
	
	# Spin control
	if Input.is_action_pressed("increase_spin"):
		current_spin = min(current_spin + 1.0, max_spin)
	
	if Input.is_action_pressed("decrease_spin"):
		current_spin = max(current_spin - 1.0, -max_spin)
	
	# Direction control (aim with stick/mouse)
	var input_dir = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	input_dir.x = 0 #up and down only
	if input_dir.length() > 0.1:
		current_direction = input_dir.normalized()
	
	# Initiate pitch powering
	if Input.is_action_just_pressed("pitch_ball") and has_ball:
		start_pitch_windup()

func start_pitch_windup():
	if not has_ball or is_winding_up:
		return
	
	is_winding_up = true
	pitch_started.emit()
	
	# TODO:Play windup animation
	#if animation_player:
		#animation_player.play(pitch_animation)

func _process_windup():
	if increasing:
		if current_power < max_power:
			current_power += power_increment
		else:
			#TODO: use stats to determine if player can throw over max power on this pitch
			current_power = max_power
			increasing = false
	else:
		if current_power > min_power:
			current_power -= power_increment
		else:
			#TODO: use stats to determine if player flubs it and throws under max power on this pitch
			current_power = min_power
			increasing = true
			

func charge_Pitch():
	if active:
		# Stop the timer and return the current power when button is pressed again
		power_timer.stop()
		active = false
		print("Final Power:", current_power)
	else: # Start the power scaling process
		current_power = min_power
		increasing = true
		active = true
		power_timer.start()
		print("Scaling power...")

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
