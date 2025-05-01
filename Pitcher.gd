class_name Pitcher
extends BallPlayer

enum currentPitch {CURVEBALL,
FASTBALL,
KNUCKLEBALL,
CHANGEUP}

## Signals
signal ball_pitched(power: float, spin: float, direction: Vector2, position: Vector2)
signal pitch_started
signal pitch_parameters_changed(power: float, spin: float, direction: Vector2)

## Pitching parameters
@export_group("Pitching Controls")
@export var max_power: float = 106.0
@export var max_spin: float = 50.0
@export var pitch_animation: String = "pitch"
@export var windup_time: float = 0.5
@export var curveball: float = 0.9#speed consistency with curveball
@export var fastball: float = 0.9#curve consistency with fastball
@export var knuckleball: float = 0.9#

## Current pitch values
var pitch_type = currentPitch.FASTBALL
var current_power: float = 0.0
var current_spin: float = 0.0
var current_direction: Vector2 = Vector2(-1, 0)
var is_winding_up: bool = false
var min_power := 40
var power_increment := 10
var power_increment_rand := 3
var spin_increment := 0.2
var spin_increment_rand := 0.1
var increasing := true
var active := false
var power_timer : Timer
var aim_max_angle : float = 0.36
var aim_increment = 0.02
var chill_timer
var can_throw := false
var has_thrown := false
var is_left_handed:= false

func _ready():
	can_throw = false
	has_ball = true
	power_timer = Timer.new()
	chill_timer =10#number of chilling frames

func _physics_process(delta):
	if is_player_controlled:
		if (is_winding_up):
			#print("and here's the windup..." + str(current_power))
			_process_windup()
			if Input.is_action_just_pressed("pitch") and can_throw:
				print("huck that sucka")
				release_ball()
				ball_pitched.emit(current_power, current_spin, current_direction, position)
			if !can_throw:
				if chill_timer > 0:
					chill_timer-= 1
				else:
					can_throw = true
		else:
			_handle_pitch_controls()
			if Input.is_action_just_pressed("strategy_primary"):
				pitch_type = currentPitch.CURVEBALL
			elif Input.is_action_just_pressed("strategy_secondary"):
				pitch_type = currentPitch.FASTBALL
			elif Input.is_action_just_pressed("strategy_tertiary"):
				print("This is where the knuckleball code goes")
				#TODO: knuckleball logic
				#pitch_type = currentPitch.KNUCKLEBALL
			elif Input.is_action_just_pressed("strategy_quaternary"):
				print("This is where the change up code goes")
				#TODO: changeup logic
				#pitch_type = currentPitch.CHANGEUP
	#super._physics_process(delta)

func _handle_pitch_controls():
	if is_winding_up:
		return
	match pitch_type:
		currentPitch.CURVEBALL:
			curve_controls()
			current_power = min_power
		currentPitch.FASTBALL:
			current_power = max_power * fastball
			fast_controls()
	#TODO: switch between pitch types
	
	if Input.is_action_just_pressed("move_down"):
		print("a littler lower")
		current_direction.y += aim_increment
		if current_direction.y > aim_max_angle:
			print("min angle")
			current_direction.y = aim_max_angle
			
	if Input.is_action_just_pressed("move_up"):
		print("a little higher")
		current_direction.y -= aim_increment
		if current_direction.y < (0-aim_max_angle):
			print("max angle")
			current_direction.y = 0-aim_max_angle
	if Input.is_action_just_pressed("pitch"):
		charge_Pitch()
		start_pitch_windup()
	

func start_pitch_windup():	
	is_winding_up = true
	pitch_started.emit()
	# TODO:Play windup animation
	#if animation_player:
		#animation_player.play(pitch_animation)

func _process_windup():
	print("winding up")
	var rng = RandomNumberGenerator.new()
	if pitch_type == currentPitch.CURVEBALL:
		curveball_windup(rng)
			

func charge_Pitch():
	if active:
		# Stop the timer and return the current power when button is pressed again
		power_timer.stop()
		active = false
		print("Final Power:", current_power)
	else: # Start the power scaling process
		#current_power = min_power
		increasing = true
		active = true
		power_timer.autostart = true#.start()
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
	#on_ball_pitched()

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

func _on_chill_timer_timeout():
	can_throw = true

func release_ball():
	has_ball = false
	has_thrown = true
	is_player_controlled = false
	
func curve_controls():
	# Spin control
	if Input.is_action_pressed("increase_spin"):
		current_spin = min(current_spin + 1.0, max_spin)
		print("more cowbell! " + str(current_spin))
	
	if Input.is_action_pressed("decrease_spin"):
		current_spin = max(current_spin - 1.0, -max_spin)
		print("less cowbell... " + str(current_spin))
		
	if Input.is_action_just_pressed("pitch"):
			charge_Pitch()
			start_pitch_windup()
		
func fast_controls():
	if Input.is_action_pressed("increase_spin"):
		current_power = min(current_power + 2.0, max_power)
		print("more heat! " + str(current_power))
	
	if Input.is_action_pressed("decrease_spin"):
		current_power = max(current_power - 2.0, min_power)
		print("kitchen too hot... " + str(current_power))

func curveball_windup(rng):
	var variance = rng.randi_range(0-power_increment_rand, power_increment_rand)
	variance = variance * (1 - focus)
	var temp_min = min_power + (max_power * curveball)/2
	if temp_min > max_power * (1 - focus):
		temp_min = max_power * (1 - focus)
	#TODO: implement curveball skill
	if increasing:
		if current_power < max_power:
			current_power += power_increment + variance
		else:
			#TODO: use stats to determine if player can throw over max power on this pitch
			current_power = max_power
			increasing = false
	else: 
		if current_power > temp_min:
			current_power -= power_increment - variance
		else:
			#TODO: use stats to determine if player flubs it and throws under max power on this pitch
			current_power = temp_min
			increasing = true

func fastball_windup(rng):
	var power_mod = 1 - (energy/100) + (1-fastball)
	current_power = current_power - (rng.randi_range(0, power_mod))
	var temp_min = (max_spin * -1 * (1 - fastball) - control)/3
	var temp_max = (max_spin * (1 - fastball) + control)/3
	if is_left_handed: #TODO: figure out which way fastballs actually curve more
		temp_min = temp_min / 2
	else:
		temp_max = temp_max / 2
	var variance = rng.randi_range(0-spin_increment_rand, spin_increment_rand)
	variance = variance * focus
	if increasing:
		if current_spin < temp_max:
			current_spin += spin_increment + variance
		else:
			#TODO: use stats to determine if player can throw over max power on this pitch
			current_spin = temp_max
			increasing = false
	else: 
		if current_spin > temp_min:
			current_spin -= spin_increment - variance
		else:
			current_spin = temp_min
			increasing = true
