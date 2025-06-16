extends Player
class_name Reworked_Pitcher

signal ball_pitched(power: float, spin: float, direction: Vector2, position: Vector2)
signal special_pitched(direction: Vector2, power: float, curves: Array[float], frames: Array[int], pitch_type: String)
# Pitching Controls
var true_max_power = 1200 * attributes.power/100 #maximum possible power at 100% energy
@export var max_power: float = true_max_power * status.energy
@export var min_power: float = 100
@export var max_curve: float = 2.0 # radians/second
@export var curve_step: float = 0.1

# Special Pitches
@export var special_pitch_cooldowns: Array[float] = [10.0, 15.0] # Seconds
@export var special_pitch_names: Array[String] = ["corker", "boomerang"]
var special_pitch_timers: Array[float] = [0.0, 0.0]
var special_pitch_available: Array[bool] = [false, false]

# AI Memory
var successful_pitches: Array[Dictionary] = []
var oppGoal: Vector2
var left_wall
var right_wall
var lastTarget: Vector2
var lastPower: float
var lastCurve: float

# Pitch State
var current_power: float = 200
var current_curve: float = 0.0
var is_aiming: bool = false
var aim_direction: Vector2 = Vector2(0,1)
var has_ball: bool = false
var increasing := true
var variance_factor = ((100 - attributes.focus)/100 + 1)/4 #between 25% and 50% maximum error
var current_variance = 0 #ranges from -100 to 100, then multiplied by variance factor
var variance_increment = 5
var hand_offset: float = 5.0 #how far to move the ball in the X to keep it from colliding
var aim_max_angle : float = 100
var aim_increment: float = 2
var target: Vector2
var field_type: String = "road"
var has_pitched: bool = false

#waiting to pitch
var pitch_frames: int = 240 #4 seconds at 60fps
var pitch_goal: int = 0 #modified target time taking into account random_effect
var random_effect:int = 120 #maximum possible disstance from pitch_frames
var current_frame:int = 0
var can_pitch:bool = false

#post-pitch combat and movement
@export var rest_position: Vector2 = Vector2(-1000, -1000)  # Set this in editor or via code
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@export var scrapping := {
	"flee": 25,
	"fight": 25,
	"chill": 25
	}
var has_attacked = false
var current_behavior: String = "waiting"
var opp_pitcher: Reworked_Pitcher
var running_positions: Array


# Nodes TODO
#var aim_arrow = $AimArrow
#var power_meter = $PowerMeter
#var curve_indicator = $CurveIndicator

func _ready():
	super._ready()
	collision_mask = 0b0000  # Collide with players (3) but not obstacles (2) or balls (1)
	position_type = "pitcher"
	behaviors = ["pitching", "going_away", "waiting", "chilling", "chasing", "fleeing", "fighting"]
	if bio.leftHanded:
		hand_offset = hand_offset * -1
	update_special_pitch_availability()

func _process(delta):
	#print("pitcher processing")
	# Update cooldowns
	for i in special_pitch_timers.size():
		if special_pitch_timers[i] > 0:
			special_pitch_timers[i] -= delta
			if special_pitch_timers[i] <= 0:
				special_pitch_available[i] = true
	
	#if is_aiming: TODO
		#update_aim_ui()

func _physics_process(delta):
	super._physics_process(delta)
	await ball
	
	if current_behavior == "going_away":
		handle_going_away()
	elif is_controlling_player and is_aiming:
		_handle_pitch_controls()
		variance_timer()
	elif !can_pitch:
		increment_pitch_time()
	elif not is_controlling_player and has_ball:
		random_variance()
		handle_ai_pitch_decision()

func increment_pitch_time():
	current_frame = current_frame + 1
	if current_frame > pitch_goal:
		can_pitch = true

func _on_pitch_phase_started():
	max_power = true_max_power * status.energy
	is_aiming = true
	current_power = lerp(min_power, max_power, 0.5)
	current_curve = 0.0

func _handle_pitch_controls():
	#print("control pitcher")
	can_move = false
	# Power adjustment
	if Input.is_action_pressed("move_up"):
		#print("more mustard")
		current_power = min(max_power, current_power + 10)
	elif Input.is_action_pressed("move_down"):
		#print("scrape some mustard off")
		current_power = max(min_power, current_power - 10)
	
	# Curve adjustment
	if Input.is_action_pressed("increase_spin"):
		current_curve = min(max_curve, current_curve + curve_step)
		#print("curl it")
	elif Input.is_action_pressed("decrease_spin"):
		current_curve = max(0-max_curve, current_curve - curve_step)
		#print("straighten it")
		#if current_curve == 0 - max_curve:
			#print("ooooooh")
	
	# Aim direction (mouse/joystick)
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input_direction = input_direction * Vector2(1,0)#we only care about x axis
	if input_direction.length() > 0.1:
		var normal = input_direction.normalized()
		if normal.x < 0:
			if target.x > 0 - aim_max_angle:
				target.x -= aim_increment
			else:
				#print("no more left")
				target.x = 0 - aim_max_angle
		elif normal.x > 0:
			if target.x < aim_max_angle:
				target.x += aim_increment
			else:
				#print("no more right")
				target.x = aim_max_angle
		aim_direction = global_position.direction_to(target).normalized()
		#print("aim it: " + str(aim_direction))
		
	if Input.is_action_just_pressed("pitch"):
		print("throw it")
		execute_pitch("normal")
		has_pitched = true
	elif Input.is_action_just_pressed("sp_pitch_1") and special_pitch_available[0]:
		print("special pitch pressed")
		execute_pitch(special_pitch_names[0])
		has_pitched = true
	elif Input.is_action_just_pressed("sp_pitch_2") and special_pitch_available[1]:
		print("special pitch pressed")
		execute_pitch(special_pitch_names[1])
		has_pitched = true
	if has_pitched:
		go_away()
		
func prepare_ai_to_pitch():
	can_pitch = false
	pitch_goal = pitch_frames + randi_range(0-random_effect, random_effect)

func handle_ai_pitch_decision():
	if !can_pitch: return
	var target = Vector2(
		randf_range(-60,60),
		randf_range(-50,75)
	)
	if status.energy > 50:
		current_power = randf_range(attributes.power*2, attributes.power*3)*4
		status.energy -= (100-attributes.endurance)*5
	else:
		current_power = randf_range(attributes.power, attributes.power*2)*4
		status.energy -= (100-attributes.endurance)*2
	var weight_chance = randi_range(0,10)
	if weight_chance <= 6: current_curve = randf_range(-max_curve/4, max_curve/4)
	elif weight_chance <= 9: current_curve = randf_range(-max_curve/2, max_curve/2)
	else: current_curve = randf_range(-max_curve, max_curve)
	random_variance()
	perform_ai_normal_pitch(target)
	has_pitched = true


func execute_pitch(pitch_type: String):
	is_aiming = false
	ball.last_hit_by = self
	var ball_position = Vector2(global_position.x + hand_offset, global_position.y)
	ball.global_position = ball_position
	match pitch_type:
		"normal":
			perform_normal_pitch()
			#ball_pitched.emit(current_power, current_curve, aim_direction, ball_position)
		"fake_curve":
			perform_fake_curve_pitch()
		"zig_zag":
			perform_zig_zag_pitch()
		"knuckler":
			perform_knuckler_pitch()
		"bouncer":
			perform_bouncer_pitch()
		"looper":
			perform_looper_pitch()
		"corker":
			perform_corker_pitch()
		"boomerang":
			perform_boomerang_pitch()
	
	# Handle special pitch cooldown
	var sp_index = special_pitch_names.find(pitch_type)
	if sp_index >= 0:
		special_pitch_available[sp_index] = false
		special_pitch_timers[sp_index] = special_pitch_cooldowns[sp_index] * (1.2 - (attributes.confidence / 100.0))

func perform_ai_normal_pitch(target):
	print("robot launching ball")
	aim_direction = global_position.direction_to(target).normalized()
	var varied_direction = aim_direction.rotated(current_variance * variance_factor)   
	var huck = current_power * varied_direction
	print("aim with variance: " + str(aim_direction))
	release_ball()
	ball_pitched.emit(huck, current_curve)
	go_away()

#normal pitch curves
func perform_normal_pitch():
	print("tossing the ball")
	status.energy = status.energy - (10 - attributes.endurance/10) #more endurance, less energy loss
	var varied_direction = aim_direction.normalized()
	varied_direction = varied_direction.rotated(current_variance * variance_factor)   
	#TODO: modify for different fields
	if field_type == "road" || field_type == "wide_road":
		if varied_direction.y > 0:
			varied_direction.y = varied_direction.y * -1
	var huck = current_power * varied_direction
	print("aim with variance: " + str(aim_direction))
	release_ball()
	ball_pitched.emit(huck, current_curve)

#looks like it will curve but straightens out
func perform_fake_curve_pitch():
	print("throwing a fake curve")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [-2.4, 8, 0.0]
	var frames: Array[int] = [40, 50, 60]
	current_power = 300
	special_pitched.emit(aim_direction, current_power, curves, frames, "fake_curve")
	release_ball()

#makes some sharp turns
func perform_zig_zag_pitch():
	print("left, no the other left")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [0, 100, 0, -100, 0]
	var frames: Array[int] = [20, 22, 42, 44, 200]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "zig_zag")
	release_ball()
	pass
	pass
	
#does a loop-the-loop
func perform_looper_pitch():
	print("throw a barrel roll")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [0, 40, 0]
	var frames: Array[int] = [50, 75, 120]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "looper")
	release_ball()
	pass

#squiggles back and forth
func perform_knuckler_pitch():
	print("throwing a knuckleball")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [-5, 5, -5, 5, -5, 5]
	var frames: Array[int] = [10, 20, 30, 40, 50, 60]
	current_power = 300
	special_pitched.emit(aim_direction, current_power, curves, frames, "knuckler")
	release_ball()
	pass
	
func find_wall_normal(wall:StaticBody2D) -> Vector2:
	if wall.global_position.x < global_position.x:
		return Vector2.RIGHT
	else:
		return Vector2.LEFT
	

#curves, then makes a sharp turn and goes straight, like it bounced off the ground
func perform_bouncer_pitch():
	print("throwing a bouncer")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [2.4, -100, 0.0]
	var frames: Array[int] = [40, 42, 60]
	current_power = 300
	special_pitched.emit(aim_direction, current_power, curves, frames, "bouncer")
	release_ball()
	pass
	
#does a weird left turn, then curves straightish
func perform_corker_pitch():
	print("makes no sense but it's cool")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [0.5, -120, 120, 0.5]
	var frames: Array[int] = [40, 46, 58, 90]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "corker")
	release_ball()
	pass
	
#turns left and comes back
func  perform_boomerang_pitch():
	print("crikey")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [0, -50, 0.0, -50, 0, -50, 0]
	var frames: Array[int] = [50, 56, 58, 62, 74, 80]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "boomerang")
	release_ball()
	pass

func update_special_pitch_availability():
	for i in special_pitch_available.size():
		special_pitch_available[i] = special_pitch_timers[i] <= 0

#func update_aim_ui():
	# Update power meter
	#power_meter.value = (current_power - min_power) / (max_power - min_power) * 100
	
	# Update curve indicator
	#curve_indicator.rotation = current_curve * 0.5
	#curve_indicator.modulate = Color.RED if current_curve < 0 else Color.BLUE
	
	# Update aim arrow
	#aim_arrow.rotation = aim_direction.angle()
	#aim_arrow.scale.x = current_power / max_power * 1.5

func _on_goal_aced():
		print("aced it")
		# TODO: Add pitch to successful pitches if not already there

			
func get_closest_wall():
	if bio.leftHanded:
		return right_wall
	else:
		return left_wall

#little timing minigame to make sure the pitch goes exactly as designed for human players
func variance_timer():
	if increasing:
		if current_variance < 100:
			current_variance = current_variance + variance_increment
		else:
			current_variance = 100
			increasing = false
	else:
		if current_variance > -100:
			current_variance = current_variance - variance_increment
		else:
			current_variance = -100
			increasing = true
			
func random_variance():
	current_variance = randi_range(1,100)

func release_ball():
	print("ball released")
	has_ball = false
	is_aiming = false
	is_controlling_player = false
	ball.last_hit_by = self
	
func go_away():
	set_physics_process(true)
	current_behavior = "going_away"
	is_controlling_player = false
	has_ball = false
	can_move = false
	
	
#TODO: change this for different fields
func prepare_target_position():
	target = Vector2(0,0)
	#print("target position: " + str(target))
	
func chase():
	var clockwise
	#TODO: if shortest path to opposing player is clockwise:
	clockwise = true
	move_around(clockwise)
	
func flee():
	var clockwise
	#TODO: if shortest path to opposing player is clockwise:
	clockwise = false
	move_around(clockwise)
	
	
func chill():
	#TODO: have some idle movement
	pass
	
func fight_or_flight(opponent: Reworked_Pitcher):
	var random
	
func move_around(clockwise:bool):
	var navAgent = $NavigationAgent2D
	if clockwise:
		#run around clockwise
		pass
	else:
		#run around counterclockwise
		pass
		
func handle_going_away():
	var move_direction: Vector2
	move_direction = global_position.direction_to(rest_position)
	velocity = move_direction * attributes.speed
	move_and_slide()
	
	# Check if we've reached our destination
	if global_position.distance_to(rest_position) <= 1:
		print("alright, I'm outta here")
		current_behavior = "chilling"
		velocity = Vector2.ZERO
