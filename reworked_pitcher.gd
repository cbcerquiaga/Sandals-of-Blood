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

# AI Memory and Decision Making
var successful_pitches: Array[Dictionary] = []
var pitch_success_threshold: int = 3 # How many times a pitch needs to succeed to be "favored"
var favor_successful_chance: float = 0.3 # 30% chance to use a favored pitch type

# AI Target Range (relative to pitcher position)
var target_x_min: float = -60.0
var target_x_max: float = 60.0
var target_y_min: float = -50.0
var target_y_max: float = 75.0

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

func _ready():
	super._ready()
	collision_mask = 0b0000  # Collide with players (3) but not obstacles (2) or balls (1)
	position_type = "pitcher"
	behaviors = ["pitching", "going_away", "waiting", "chilling", "chasing", "fleeing", "fighting"]
	if bio.leftHanded:
		hand_offset = hand_offset * -1
	update_special_pitch_availability()

func _process(delta):
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
	can_move = false
	# Power adjustment
	if Input.is_action_pressed("move_up"):
		current_power = min(max_power, current_power + 10)
	elif Input.is_action_pressed("move_down"):
		current_power = max(min_power, current_power - 10)
	
	# Curve adjustment
	if Input.is_action_pressed("increase_spin"):
		current_curve = min(max_curve, current_curve + curve_step)
	elif Input.is_action_pressed("decrease_spin"):
		current_curve = max(0-max_curve, current_curve - curve_step)
	
	# Aim direction (mouse/joystick)
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input_direction = input_direction * Vector2(1,0)#we only care about x axis
	if input_direction.length() > 0.1:
		var normal = input_direction.normalized()
		if normal.x < 0:
			if target.x > 0 - aim_max_angle:
				target.x -= aim_increment
			else:
				target.x = 0 - aim_max_angle
		elif normal.x > 0:
			if target.x < aim_max_angle:
				target.x += aim_increment
			else:
				target.x = aim_max_angle
		aim_direction = global_position.direction_to(target).normalized()
		
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

# NEW AI PITCH DECISION SYSTEM
func handle_ai_pitch_decision():
	if !can_pitch: 
		return
	
	# Determine pitch type based on groove and confidence
	var pitch_type = ai_select_pitch_type()
	
	# Select target position
	var selected_target = ai_select_target(pitch_type)
	
	# Execute the pitch
	match pitch_type:
		"normal":
			ai_execute_normal_pitch(selected_target)
		_:
			ai_execute_special_pitch(pitch_type, selected_target)
	
	has_pitched = true

func ai_select_pitch_type() -> String:
	# Calculate max groove based on confidence
	var max_groove = attributes.confidence
	var current_groove = min(status.groove, max_groove)
	
	# Check if we should favor a previously successful pitch
	if randf() < favor_successful_chance and successful_pitches.size() > 0:
		var favored_pitch = get_favored_pitch_type()
		if favored_pitch != "" and can_use_pitch_type(favored_pitch):
			print("AI using favored pitch: " + favored_pitch)
			return favored_pitch
	
	# Determine available special pitches
	var available_specials: Array[String] = []
	for i in special_pitch_names.size():
		if special_pitch_available[i]:
			available_specials.append(special_pitch_names[i])
	
	# Calculate special pitch chance based on groove
	var special_chance = current_groove / 100.0 * 0.4  # Max 40% chance at 100 groove
	
	if randf() < special_chance and available_specials.size() > 0:
		var selected_special = available_specials[randi() % available_specials.size()]
		print("AI selected special pitch: " + selected_special)
		return selected_special
	else:
		print("AI selected normal pitch")
		return "normal"

func get_favored_pitch_type() -> String:
	var pitch_counts = {}
	
	# Count successful pitches by type
	for pitch in successful_pitches:
		var pitch_type = pitch.get("type", "normal")
		if pitch_counts.has(pitch_type):
			pitch_counts[pitch_type] += 1
		else:
			pitch_counts[pitch_type] = 1
	
	# Find pitch types with enough successes
	var favored_pitches: Array[String] = []
	for pitch_type in pitch_counts.keys():
		if pitch_counts[pitch_type] >= pitch_success_threshold:
			favored_pitches.append(pitch_type)
	
	if favored_pitches.size() > 0:
		return favored_pitches[randi() % favored_pitches.size()]
	
	return ""

func can_use_pitch_type(pitch_type: String) -> bool:
	if pitch_type == "normal":
		return true
	
	var sp_index = special_pitch_names.find(pitch_type)
	return sp_index >= 0 and special_pitch_available[sp_index]

func ai_select_target(pitch_type: String) -> Vector2:
	# Check for successful targets with this pitch type
	var successful_targets = get_successful_targets_for_pitch_type(pitch_type)
	
	if successful_targets.size() > 0 and randf() < 0.6:  # 60% chance to use successful target
		var selected_target = successful_targets[randi() % successful_targets.size()]
		print("AI using successful target: " + str(selected_target))
		return selected_target
	
	# Generate random target with aggression bias toward center
	var aggression_factor = attributes.aggression / 100.0
	
	# For X coordinate: more aggressive = bias toward center (0)
	var x_coord: float
	if randf() < aggression_factor:
		# Aggressive: bias toward center with smaller range
		var center_range = lerp(30.0, 10.0, aggression_factor)  # Range gets smaller with more aggression
		x_coord = randf_range(-center_range, center_range)
	else:
		# Non-aggressive: use full range
		x_coord = randf_range(target_x_min, target_x_max)
	
	# Y coordinate remains fully random
	var y_coord = randf_range(target_y_min, target_y_max)
	
	var selected_target = Vector2(x_coord, y_coord)
	print("AI selected target (aggression: " + str(aggression_factor) + "): " + str(selected_target))
	return selected_target

func get_successful_targets_for_pitch_type(pitch_type: String) -> Array[Vector2]:
	var targets: Array[Vector2] = []
	
	for pitch in successful_pitches:
		if pitch.get("type", "normal") == pitch_type:
			targets.append(pitch.get("target", Vector2.ZERO))
	
	return targets

func ai_execute_normal_pitch(target_pos: Vector2):
	print("AI executing normal pitch")
	
	# Set target and aim direction
	target = target_pos
	aim_direction = global_position.direction_to(target).normalized()
	
	# Calculate power based on aggression and energy
	var aggression_factor = attributes.aggression / 100.0
	var energy_factor = status.energy / 100.0
	
	if energy_factor > 0.5:
		# High energy: use aggression to determine power (more aggressive = more power)
		current_power = lerp(attributes.power * 2, attributes.power * 4, aggression_factor) * 4
		status.energy -= (100 - attributes.endurance) * 5
	else:
		# Low energy: conservative power regardless of aggression
		current_power = randf_range(attributes.power, attributes.power * 2) * 4
		status.energy -= (100 - attributes.endurance) * 2
	
	# Calculate curve based on focus (higher focus = more intentional curve)
	var focus_factor = attributes.focus / 100.0
	var curve_intensity = lerp(max_curve / 4, max_curve, focus_factor)
	
	var curve_roll = randi_range(0, 10)
	if curve_roll <= 6:
		current_curve = randf_range(-curve_intensity / 2, curve_intensity / 2)
	elif curve_roll <= 9:
		current_curve = randf_range(-curve_intensity, curve_intensity)
	else:
		current_curve = randf_range(-max_curve, max_curve)
	
	# Apply variance and execute
	random_variance()
	perform_ai_normal_pitch(target)

func ai_execute_special_pitch(pitch_type: String, target_pos: Vector2):
	print("AI executing special pitch: " + pitch_type)
	
	# Set target for special pitch
	target = target_pos
	
	# Execute the specific special pitch
	execute_pitch(pitch_type)

# Store successful pitch data - called from external script
func store_successful_pitch(pitch_data: Dictionary):
	print("Storing successful pitch: " + str(pitch_data))
	successful_pitches.append(pitch_data)
	
	# Optional: Limit stored pitches to prevent infinite growth
	if successful_pitches.size() > 50:
		successful_pitches.pop_front()

# Helper function to create pitch data for storage
func get_current_pitch_data(pitch_type: String) -> Dictionary:
	return {
		"type": pitch_type,
		"target": target,
		"power": current_power,
		"curve": current_curve,
		"energy_used": (100 - attributes.endurance) * (5 if status.energy > 50 else 2)
	}

func execute_pitch(pitch_type: String):
	is_aiming = false
	ball.last_hit_by = self
	var ball_position = Vector2(global_position.x + hand_offset, global_position.y)
	ball.global_position = ball_position
	
	match pitch_type:
		"normal":
			perform_normal_pitch()
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
	print("AI launching ball")
	aim_direction = global_position.direction_to(target).normalized()
	var varied_direction = aim_direction.rotated(current_variance * variance_factor)   
	var huck = current_power * varied_direction
	print("AI aim with variance: " + str(varied_direction))
	release_ball()
	ball_pitched.emit(huck, current_curve)
	go_away()

# Rest of the existing special pitch functions remain unchanged
func perform_normal_pitch():
	print("tossing the ball")
	status.energy = status.energy - (10 - attributes.endurance/10)#more endurance, less energy loss
	var varied_direction = aim_direction.normalized()
	varied_direction = varied_direction.rotated(current_variance * variance_factor)   
	if field_type == "road" || field_type == "wide_road":
		if varied_direction.y > 0:
			varied_direction.y = varied_direction.y * -1
	var huck = current_power * varied_direction
	print("aim with variance: " + str(aim_direction))
	release_ball()
	ball_pitched.emit(huck, current_curve)

func perform_fake_curve_pitch():
	print("throwing a fake curve")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [-2.4, 8, 0.0]
	var frames: Array[int] = [40, 50, 60]
	current_power = 300
	special_pitched.emit(aim_direction, current_power, curves, frames, "fake_curve")
	release_ball()

func perform_zig_zag_pitch():
	print("left, no the other left")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [0, 100, 0, -100, 0]
	var frames: Array[int] = [20, 22, 42, 44, 200]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "zig_zag")
	release_ball()
	
func perform_looper_pitch():
	print("throw a barrel roll")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [0, 40, 0]
	var frames: Array[int] = [50, 75, 120]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "looper")
	release_ball()

func perform_knuckler_pitch():
	print("throwing a knuckleball")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [-5, 5, -5, 5, -5, 5]
	var frames: Array[int] = [10, 20, 30, 40, 50, 60]
	current_power = 300
	special_pitched.emit(aim_direction, current_power, curves, frames, "knuckler")
	release_ball()
	
func find_wall_normal(wall:StaticBody2D) -> Vector2:
	if wall.global_position.x < global_position.x:
		return Vector2.RIGHT
	else:
		return Vector2.LEFT

func perform_bouncer_pitch():
	print("throwing a bouncer")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [2.4, -100, 0.0]
	var frames: Array[int] = [40, 42, 60]
	current_power = 300
	special_pitched.emit(aim_direction, current_power, curves, frames, "bouncer")
	release_ball()
	
func perform_corker_pitch():
	print("makes no sense but it's cool")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [0.5, -120, 120, 0.5]
	var frames: Array[int] = [40, 46, 58, 90]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "corker")
	release_ball()
	
func perform_boomerang_pitch():
	print("crikey")
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [0, -50, 0.0, -50, 0, -50, 0]
	var frames: Array[int] = [50, 56, 58, 62, 74, 80]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "boomerang")
	release_ball()

func update_special_pitch_availability():
	for i in special_pitch_available.size():
		special_pitch_available[i] = special_pitch_timers[i] <= 0

func _on_goal_aced():
	print("aced it")

func get_closest_wall():
	if bio.leftHanded:
		return right_wall
	else:
		return left_wall

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

func prepare_target_position():
	target = Vector2(0,0)
	
func chase():
	var clockwise = true
	move_around(clockwise)
	
func flee():
	var clockwise = false
	move_around(clockwise)
	
func chill():
	pass
	
func fight_or_flight(opponent: Reworked_Pitcher):
	var random
	
func move_around(clockwise:bool):
	var navAgent = $NavigationAgent2D
	if clockwise:
		pass
	else:
		pass
		
func handle_going_away():
	var move_direction: Vector2
	move_direction = global_position.direction_to(rest_position)
	velocity = move_direction * attributes.speed
	move_and_slide()
	
	if global_position.distance_to(rest_position) <= 1:
		print("alright, I'm outta here")
		current_behavior = "chilling"
		velocity = Vector2.ZERO
