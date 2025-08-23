extends Player
class_name Reworked_Pitcher

signal ball_pitched(power: float, spin: float, direction: Vector2, position: Vector2)
signal special_pitched(direction: Vector2, power: float, curves: Array[float], frames: Array[int], pitch_type: String)

# Pitching Controls
var true_max_power = 1200 * (attributes.power * attributes.throwing/100)/100 #maximum possible power at 100% energy
@export var max_power: float = true_max_power * status.energy
@export var min_power: float = 100
@export var max_curve: float = 2.0 # radians/second
@export var curve_step: float = 0.1
@onready var powerbar = $UI/PowerBar



# AI Memory and Decision Making
var successful_pitches: Array[Dictionary] = []
var pitch_success_threshold: int = 3 # How many times a pitch needs to succeed to be "favored"
var favor_successful_chance: float = 0.3 # 30% chance to use a favored pitch type
var most_recent_pitch #dictionary of the data from current pitch

# AI Target Range (relative to pitcher position)
var target_x_min: float = -60.0
var target_x_max: float = 60.0
var target_y_min: float = -50.0
var target_y_max: float = 75.0

# Movement constants
const MAX_DIRECTION_CHANGES := 3 #double juke and change
const REACTION_CHECK_INTERVAL := 2.0
const CLOSE_DISTANCE_THRESHOLD := 0.45

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
var variance_factor = ((100 - attributes.accuracy)/100 + 1)/4 #between 25% and 50% maximum error
var current_variance = 0 #ranges from -100 to 100, then multiplied by variance factor
var variance_increment = 5
var hand_offset: float = 5.0 #how far to move the ball in the X to keep it from colliding
var aim_max_angle : float = 100
var aim_increment: float = 2
var target: Vector2
var field_type: String = "road"
var has_pitched: bool = false

#waiting to pitch
var pitch_frames: int = 60 #1 second at 60fps
var pitch_goal: int = 0 #modified target time taking into account random_effect
var random_effect:int = 60 #maximum possible distance from pitch_frames
var current_frame:int = 0
var can_pitch:bool = false

#post-pitch combat and movement
@export var rest_position: Vector2 = Vector2(-1000, -1000)  # Set this in editor or via code
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@export var scrapping := {
	"flee": 20,
	"fight": 50,
	"chill": 25,
	"track": 5
	}
var current_path_index: int = 0
var current_waypoint: Vector2
var next_waypoint: Vector2
var has_attacked = false
var has_arrived = false #ready to fight
var opp_pitcher: Reworked_Pitcher
var running_positions: Array
var moving_clockwise: bool
var direction_changes: int = 0
#chill specific
var chill_area_min: Vector2 = Vector2(-10, -5)
var chill_area_max: Vector2 = Vector2(10, 5)
var current_chill_target: Vector2
var chill_target_reached_threshold: float = 5.0
#no chill
var is_chasing: bool = false
const chase_threshold: int = 40
var is_fleeing: bool = false
var last_reaction_check: float = 0.0
var has_made_first_move: bool = false
var legal_first_moves: Array

func _ready():
	super._ready()
	current_behavior = "waiting"
	collision_mask = 0b0000  # Collide with players (3) but not obstacles (2) or balls (1)
	position_type = "pitcher"
	max_curve = 2.0 * (attributes.focus + attributes.throwing)/200
	restore_behaviors()
	if bio.leftHanded:
		hand_offset = hand_offset * -1
		
func restore_behaviors():
	behaviors = ["pitching", "going_away", "deciding", "waiting", "chilling", "chasing", "fleeing", "fighting"]

func _physics_process(delta):
	super._physics_process(delta)
	await ball
	update_special_pitch_availability()
	powerbar.visible = false
	if Input.is_action_pressed("pitch"):
		human_ready = true
		prepare_ai_to_pitch()
	if current_behavior == "waiting":
		has_arrived = false
		has_attacked = false
		current_waypoint = Vector2.ZERO
	elif current_behavior == "deciding":
		current_waypoint = Vector2.ZERO
		if !opp_pitcher or opp_pitcher.has_arrived == false:
			can_move = false
			return
		else:
			can_move = true
		velocity = Vector2.ZERO
		if has_arrived and opp_pitcher.has_arrived == true:
			fight_or_flight()
	elif current_behavior == "fallen":
		return
	elif current_behavior == "fighting":
		fight_footwork()
	elif current_behavior == "chilling":
		chill()
		check_human_input()
	elif current_behavior == "chasing":
		chase()
		check_human_input()
	elif current_behavior == "fleeing":
		flee()
		check_human_input()
	elif current_behavior == "tracking":
		track()
		check_human_input()
	elif current_behavior == "going_away":
		handle_going_away()
	if is_controlling_player and is_aiming:
		current_behavior = "pitching"
		has_arrived = false
		powerbar.visible = true
		current_waypoint = Vector2.ZERO
		velocity = Vector2.ZERO
		_handle_pitch_controls()
		variance_timer()
		handle_powerbar()
	elif !can_pitch:
		increment_pitch_time()
	elif not is_controlling_player and has_ball:
		has_arrived = false
		random_variance()
		handle_ai_pitch_decision()
		
func check_human_input():
	if team == 1:
		if Input.is_action_just_pressed("pitcher_chill"):
			current_behavior = "chilling"
		elif Input.is_action_just_pressed("pitcher_chase"):
			current_behavior = "chasing"
		elif Input.is_action_just_pressed("pitcher_flee"):
			current_behavior = "tracking"
		elif Input.is_action_just_pressed("pitcher_turn"):
			moving_clockwise = !moving_clockwise
			if current_behavior == "chilling":
				current_behavior = "chasing"
			change_directions()

func change_directions():
	var next_index = current_path_index
	if moving_clockwise:
		next_index = next_index + 1
		if next_index > running_positions.size() - 1:
			next_index = 0
	else:
		next_index = next_index - 1
		if next_index < 0:
			next_index = running_positions.size() - 1
	current_path_index = next_index
	current_waypoint = running_positions[current_path_index].global_position
	var direction_to_waypoint = global_position.direction_to(current_waypoint)
	var speed = attributes.sprint_speed if status.boost > 0 else attributes.speed
	velocity = direction_to_waypoint * speed

func increment_pitch_time():
	current_frame = current_frame + 1
	if current_frame > pitch_goal:
		can_pitch = true

func _on_pitch_phase_started():
	status.boost = max(status.boost, 10) 
	has_made_first_move = false
	max_power = true_max_power * status.energy
	is_aiming = true
	current_power = lerp(min_power, max_power, 0.5)
	current_curve = 0.0
	# Reset movement states when new pitch starts
	is_chasing = false
	is_fleeing = false
	direction_changes = 0
	current_behavior = "waiting"  # Add this line
	prepare_target_position()

func _handle_pitch_controls():
	can_move = false
	if target == Vector2.ZERO:
		prepare_target_position()
		aim_direction = global_position.direction_to(target).normalized()
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
		execute_pitch("normal")
	elif Input.is_action_just_pressed("sp_pitch_1") and special_pitch_available[0]:
		execute_pitch(special_pitch_names[0])
	elif Input.is_action_just_pressed("sp_pitch_2") and special_pitch_available[1]:
		execute_pitch(special_pitch_names[1])
	elif Input.is_action_just_pressed("sp_pitch_3") and special_pitch_available[2]:
		execute_pitch(special_pitch_names[2])
	if has_pitched:
		go_away()

func prepare_ai_to_pitch():
	can_pitch = false
	pitch_goal = pitch_frames + randi_range(0-random_effect, random_effect) #0-120 frames

func handle_ai_pitch_decision():
	if !human_ready:
		#be a gentleman. dont throw until the human is ready
		return
	if !can_pitch: 
		return
	
	var pitch_type = ai_select_pitch_type()
	var selected_target = ai_select_target(pitch_type)
	
	match pitch_type:
		"normal":
			ai_execute_normal_pitch(selected_target)
		_:
			ai_execute_special_pitch(pitch_type, selected_target)
	
	has_pitched = true
	status.groove += 2
	human_ready = false

func ai_select_pitch_type() -> String:
	var max_groove = attributes.confidence
	var current_groove = min(status.groove, max_groove)
	
	if randf() < favor_successful_chance and successful_pitches.size() > 0:
		var favored_pitch = get_favored_pitch_type()
		if favored_pitch != "" and can_use_pitch_type(favored_pitch):
			return favored_pitch
	
	var available_specials: Array[String] = []
	for i in special_pitch_names.size():
		if special_pitch_available[i]:
			available_specials.append(special_pitch_names[i])
	
	var special_chance = current_groove / 100.0 * 0.4
	
	if randf() < special_chance and available_specials.size() > 0:
		return available_specials[randi() % available_specials.size()]
	else:
		return "normal"

func get_favored_pitch_type() -> String:
	var pitch_counts = {}
	
	for pitch in successful_pitches:
		var pitch_type = pitch.get("type", "normal")
		if pitch_counts.has(pitch_type):
			pitch_counts[pitch_type] += 1
		else:
			pitch_counts[pitch_type] = 1
	
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
	var successful_targets = get_successful_targets_for_pitch_type(pitch_type)
	
	if successful_targets.size() > 0 and randf() < 0.6:
		return successful_targets[randi() % successful_targets.size()]
	
	var aggression_factor = attributes.aggression / 100.0
	
	var x_coord: float
	if randf() < aggression_factor:
		var center_range = lerp(30.0, 10.0, aggression_factor)
		x_coord = randf_range(-center_range, center_range)
	else:
		x_coord = randf_range(target_x_min, target_x_max)
	
	var y_coord = randf_range(target_y_min, target_y_max)
	
	return Vector2(x_coord, y_coord)

func get_successful_targets_for_pitch_type(pitch_type: String) -> Array[Vector2]:
	var targets: Array[Vector2] = []
	
	for pitch in successful_pitches:
		if pitch.get("type", "normal") == pitch_type:
			targets.append(pitch.get("target", Vector2.ZERO))
	
	return targets

func ai_execute_normal_pitch(target_pos: Vector2):
	target = target_pos
	aim_direction = global_position.direction_to(target).normalized()
	
	var aggression_factor = attributes.aggression / 100.0
	var energy_factor = status.energy / 100.0
	
	if energy_factor > 0.5:
		current_power = lerp((attributes.power* attributes.throwing/100) * 2, (attributes.power* attributes.throwing/100) * 4, aggression_factor) * 4
		status.energy -= (100 - attributes.endurance) * 5
	else:
		current_power = randf_range((attributes.power* attributes.throwing/100), (attributes.power* attributes.throwing/100) * 2) * 4
		status.energy -= (100 - attributes.endurance) * 2
	
	var focus_factor = attributes.focus / 100.0
	var curve_intensity = lerp(max_curve / 4, max_curve, focus_factor)
	
	var curve_roll = randi_range(0, 10)
	if curve_roll <= 6:
		current_curve = randf_range(-curve_intensity / 2, curve_intensity / 2)
	elif curve_roll <= 9:
		current_curve = randf_range(-curve_intensity, curve_intensity)
	else:
		current_curve = randf_range(-max_curve, max_curve)
	
	random_variance()
	perform_ai_normal_pitch(target)

func ai_execute_special_pitch(pitch_type: String, target_pos: Vector2):
	target = target_pos
	execute_pitch(pitch_type)

func store_successful_pitch():
	if !most_recent_pitch:
		return
	successful_pitches.append(most_recent_pitch)

func get_current_pitch_data(pitch_type: String) -> Dictionary:
	return {
		"type": pitch_type,
		"target": target,
		"power": current_power,
		"curve": current_curve
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
		"zig-zag":
			perform_zig_zag_pitch()
		"knuckler":
			perform_knuckler_pitch()
		"bouncer":
			perform_bouncer_pitch()
		"looper":
			perform_looper_pitch()
		"corker":
			perform_corker_pitch()
		"yoyo":
			perform_yoyo_pitch()
		"none":
			perform_normal_pitch()
	has_pitched = true
	
	var sp_index = special_pitch_names.find(pitch_type)
	if sp_index >= 0:
		special_pitch_available[sp_index] = false
		if status.groove >= special_pitch_groove[sp_index]:
			special_pitch_available[sp_index] = true

func perform_ai_normal_pitch(point):
	aim_direction = global_position.direction_to(point).normalized()
	var varied_direction = aim_direction.rotated(current_variance * variance_factor)   
	var huck = current_power * varied_direction
	release_ball()
	ball_pitched.emit(huck, current_curve)
	has_pitched = true
	most_recent_pitch = {"pitch_type": "normal", "power": current_power, "curve": current_curve, "direction": aim_direction}
	go_away()

func perform_normal_pitch():
	# Ensure target and aim direction are properly set
	if target == Vector2.ZERO:
		target = global_position + Vector2(0, 0 if field_type != "road" else 100)  # Default direction based on field
		aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var varied_direction = aim_direction.normalized()
	varied_direction = varied_direction.rotated(current_variance * variance_factor)   
	if field_type == "road" || field_type == "wide_road":
		if varied_direction.y > 0:
			varied_direction.y = varied_direction.y * -1
	var huck = current_power * varied_direction
	release_ball()
	ball_pitched.emit(huck, current_curve)

func perform_fake_curve_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [-2.4, 8, 0.0]
	var frames: Array[int] = [40, 50, 60]
	current_power = 300
	special_pitched.emit(aim_direction, current_power, curves, frames, "fake_curve")
	most_recent_pitch = {"pitch_type": "fake_curve", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()

func perform_zig_zag_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [0, 100, 0, -100, 0]
	var frames: Array[int] = [20, 22, 42, 44, 200]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "zig-zag")
	most_recent_pitch = {"pitch_type": "zif-zag", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()
	
func perform_looper_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [0, 40, 0]
	var frames: Array[int] = [50, 75, 120]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "looper")
	most_recent_pitch = {"pitch_type": "looper", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()

func perform_knuckler_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var knuckle = attributes.focus/5 #10 for 50, 19.8 for 99
	var curves: Array[float] = [0, 0, randf_range(-knuckle, knuckle),randf_range(-knuckle, knuckle), randf_range(-knuckle, knuckle), randf_range(-knuckle, knuckle)]
	var frames: Array[int] = [10, 20, 30, 40, 50, 60]
	current_power = 300
	special_pitched.emit(aim_direction, current_power, curves, frames, "knuckler")
	most_recent_pitch = {"pitch_type": "knuckler", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()
	
func find_wall_normal(wall:StaticBody2D) -> Vector2:
	if wall.global_position.x < global_position.x:
		return Vector2.RIGHT
	else:
		return Vector2.LEFT

func perform_bouncer_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [2.4, -100, 0.0]
	var frames: Array[int] = [40, 42, 60]
	current_power = 300
	special_pitched.emit(aim_direction, current_power, curves, frames, "bouncer")
	most_recent_pitch = {"pitch_type": "bouncer", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()
	
func perform_corker_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [0.5, -120, 120, 0.5]
	var frames: Array[int] = [40, 46, 58, 90]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "corker")
	most_recent_pitch = {"pitch_type": "corker", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()
	
func perform_yoyo_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - attributes.endurance/10)
	var curves: Array[float] = [0, -50, 0.0, -50, 0, -50, 0]
	var frames: Array[int] = [50, 56, 58, 62, 74, 80]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "yoyo")
	most_recent_pitch = {"pitch_type": "yoyo", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()

func update_special_pitch_availability():
	for i in special_pitch_available.size():
		if status.groove >= special_pitch_groove[i]:
			special_pitch_available[i] = true

func _on_goal_aced():
	game_stats.aces += 1
	status.groove += 15
	if status.groove > attributes.confidence:
		status.groove = attributes.confidence
	successful_pitches.append(most_recent_pitch)
	pass

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
	has_ball = false
	is_aiming = false
	is_controlling_player = false
	ball.last_hit_by = self
	
func go_away():
	if !has_pitched:
		return
	set_physics_process(true)
	current_behavior = "going_away"
	is_controlling_player = false
	has_ball = false
	can_move = false
	has_arrived = false  # Add this line to ensure proper state reset

func prepare_target_position():
	target = Vector2(0,0)

func chase():
	if !is_chasing:
		initialize_chase()
	var myIndex = find_closest_position_index(global_position)
	var oppIndex = find_closest_position_index(opp_pitcher.global_position)
	if myIndex == oppIndex:
		# If we're closer than chase threshold, go directly after opponent
		if global_position.distance_to(opp_pitcher.global_position) < chase_threshold:
			var direction = global_position.direction_to(opp_pitcher.global_position).normalized()
			var speed = attributes.sprint_speed if status.boost > 0 else attributes.speed
			velocity = direction * speed
			move_and_slide()
			return
		else:
			# If on same index but not close enough, force move to next waypoint
			if current_waypoint != Vector2.ZERO:
				if global_position.distance_to(current_waypoint) < 10:  # If close to current waypoint
					advance_waypoints()  # Move to next waypoint immediately
				else:
					# Move toward current waypoint but prepare for next
					var direction = global_position.direction_to(current_waypoint).normalized()
					var speed = attributes.sprint_speed if status.boost > 0 else attributes.speed
					velocity = direction * speed
					move_and_slide()
					return
	move_around()
	last_reaction_check += get_process_delta_time()
	if last_reaction_check >= REACTION_CHECK_INTERVAL && direction_changes < MAX_DIRECTION_CHANGES:
		last_reaction_check = 0.0
		reconsider_chase_direction()

func initialize_chase():
	is_chasing = true
	is_fleeing = false
	direction_changes = 0
	#lean towards one side so that both players chasing have a better chance of getting each other
	if team == 1:
		moving_clockwise = randf() < 0.75
	else:
		moving_clockwise = randf() > 0.75
	initialize_waypoints()

func reconsider_chase_direction():
	if running_positions.size() < 2:
		return
	if opp_pitcher.current_behavior == "chasing" && moving_clockwise == opp_pitcher.moving_clockwise:
		moving_clockwise = !moving_clockwise
		direction_changes += 1
		return
	var opp_predicted_pos = opp_pitcher.global_position + opp_pitcher.velocity * 0.5
	var target_index = find_closest_position_index(opp_predicted_pos)
	var my_index = find_closest_position_index(global_position)
	var clockwise_distance = calculate_clockwise_distance(my_index, target_index)
	var counter_distance = calculate_counter_distance(my_index, target_index)
	var should_change = (moving_clockwise && counter_distance < clockwise_distance * 0.8) || \
					   (!moving_clockwise && clockwise_distance < counter_distance * 0.8)
	
	if should_change && direction_changes < MAX_DIRECTION_CHANGES:
		direction_changes += 1
		moving_clockwise = !moving_clockwise

func flee():
	if !is_fleeing:
		initialize_flee()
	var speed = calculate_flee_speed()
	move_around(speed)
	if current_waypoint != Vector2.ZERO && global_position.distance_to(current_waypoint) < 5.0:
		direction_changes = 0  # Reset direction changes when reaching waypoint
		if randf_range(0,100) < attributes.reactions:
			reconsider_flee_direction()
		advance_waypoints()
	last_reaction_check += get_process_delta_time()
	if last_reaction_check >= REACTION_CHECK_INTERVAL && direction_changes < MAX_DIRECTION_CHANGES:
		last_reaction_check = 0.0
		if randf_range(0,100) < attributes.reactions:
			if opp_pitcher.current_behavior == "chilling":
				current_behavior = "chilling"
				print("bro relax")
				return
			reconsider_flee_direction()

func initialize_flee():
	is_fleeing = true
	is_chasing = false
	direction_changes = 0
	moving_clockwise = randf() < 0.5
	initialize_waypoints()

func calculate_flee_speed() -> float:
	var my_index = find_closest_position_index(global_position)
	var opp_index = find_closest_position_index(opp_pitcher.global_position)
	var current_distance = min(
		calculate_clockwise_distance(opp_index, my_index),
		calculate_counter_distance(opp_index, my_index)
	)
	
	var path_length = running_positions.size()
	var normalized_distance = float(current_distance) / path_length
	
	if normalized_distance < CLOSE_DISTANCE_THRESHOLD:
		if status.boost > 0:
			return attributes.sprint_speed
		else:
			return attributes.speed
	else:
		return attributes.speed * 0.5 #walk

func reconsider_flee_direction():
	if running_positions.size() < 2 || direction_changes >= MAX_DIRECTION_CHANGES:
		return
	
	var my_index = find_closest_position_index(global_position)
	var opp_index = find_closest_position_index(opp_pitcher.global_position)
	
	var clockwise_distance = calculate_clockwise_distance(opp_index, my_index)
	var counter_distance = calculate_counter_distance(opp_index, my_index)
	
	var should_change = (moving_clockwise && clockwise_distance < counter_distance * 0.8) || \
					   (!moving_clockwise && counter_distance < clockwise_distance * 0.8)
	
	if should_change:
		direction_changes += 1
		moving_clockwise = !moving_clockwise

func should_stop_fleeing() -> bool:
	var my_index = find_closest_position_index(global_position)
	var opp_index = find_closest_position_index(opp_pitcher.global_position)
	var current_distance = min(
		calculate_clockwise_distance(opp_index, my_index),
		calculate_counter_distance(opp_index, my_index)
	)
	
	var safe_distance = running_positions.size() * 0.4
	if current_distance >= safe_distance:
		if randf() < 0.6 or direction_changes >= MAX_DIRECTION_CHANGES:
			return true
		else:
			reconsider_flee_direction()
	return false

func chill():
	current_behavior = "chilling"
	direction_changes = 0
	if !current_chill_target or global_position.distance_to(current_chill_target) < chill_target_reached_threshold:
		current_chill_target = get_random_chill_target()
	var move_direction = global_position.direction_to(current_chill_target)
	velocity = move_direction * (attributes.speed * 0.1)
	move_and_slide()
	
	last_reaction_check += get_process_delta_time()
	if last_reaction_check >= REACTION_CHECK_INTERVAL:
		last_reaction_check = 0.0
		check_chill_state()
		
func fight_footwork():
	current_behavior = "fighting"
	if !opp_pitcher:
		return
	var direction: Vector2
	if global_position.distance_to(opp_pitcher.global_position) > 30:
		direction = global_position.direction_to(opp_pitcher.global_position)
	else:
		direction = Vector2(randf_range(-1,1), randf_range(-1,1))
	velocity = direction * (attributes.speed * 0.1)
	move_and_slide()
	
func fight_or_flight():
	var base_flee = scrapping["flee"]
	var base_fight = scrapping["fight"]
	var base_chill = scrapping["chill"]
	var base_track = scrapping["track"]
	var attribute_modifier = 0.0
	
	var tough_diff = opp_pitcher.attributes.toughness - attributes.toughness
	var speed_diff = opp_pitcher.attributes.speed - attributes.speed
	
	if tough_diff > 0:
		attribute_modifier = tough_diff / 100.0
		base_flee += attribute_modifier * tough_diff
		base_fight -= attribute_modifier * tough_diff
	else:
		attribute_modifier = abs(tough_diff) / 100.0
		base_fight += attribute_modifier * tough_diff
		base_flee -= attribute_modifier * tough_diff
	
	if speed_diff > 0:
		var speed_mod = speed_diff / 100.0
		base_fight -= speed_mod * speed_mod
		base_chill += speed_mod * speed_mod
	
	base_flee = clamp(base_flee, 0, 100)
	base_fight = clamp(base_fight, 0, 100)
	base_chill = clamp(base_chill, 0, 100)
	base_track = clamp(base_track, 0, 100)
	var total = base_flee + base_fight + base_chill
	var flee_chance = base_flee / total
	var fight_chance = base_fight / total
	var track_chance = base_track / total

	var roll = randf()
	if roll < flee_chance:
		current_behavior = "fleeing"
		print("get the hell away from me you freak")
		flee()
	elif roll < flee_chance + fight_chance:
		current_behavior = "chasing"
		print("get over here you little shit")
		chase()
	elif roll < flee_chance + fight_chance + track_chance:
		current_behavior = "tracking"
		print("time for a jog")
	else:
		current_behavior = "chilling"
		print("bro I ain't running")
		chill()

#just go around the outside of the field like a track
func track():
	if current_waypoint == Vector2.ZERO:
		moving_clockwise = randf() < 0.5
		initialize_waypoints()
	else:
		move_around()
	
func move_around(input_speed: float = -1.0):
	if current_waypoint == Vector2.ZERO:
		initialize_waypoints()
	if global_position.distance_to(current_waypoint) < 5.0:
		advance_waypoints()
	var speed
	if input_speed == -1:
		if status.boost > 0:
			speed = attributes.sprint_speed
		else:
			speed = attributes.speed
	else:
		speed = input_speed
	var base_direction = global_position.direction_to(current_waypoint)
	velocity = base_direction * speed
	move_and_slide()
	if status.boost > 0 and speed == attributes.sprint_speed:
		status.boost = max(0, status.boost - 0.25)

func initialize_waypoints():
	if moving_clockwise:
		current_waypoint = running_positions[legal_first_moves[0]].global_position
		current_path_index = legal_first_moves[0]
	else:
		current_waypoint = running_positions[legal_first_moves[1]].global_position
		current_path_index = legal_first_moves[1]
	print("waypoing position at init: ", current_waypoint)
	# Force movement to the first waypoint to prevent corner cutting
	var direction_to_waypoint = global_position.direction_to(current_waypoint)
	velocity = direction_to_waypoint * attributes.speed

func advance_waypoints():
	#print("team: ", team," old index: ", current_path_index, " clockwise: ", moving_clockwise)
	var next_index = current_path_index
	if moving_clockwise:
		next_index = next_index + 1
		if next_index > running_positions.size() - 1:
			next_index = 0
	else:
		next_index = next_index - 1
		if next_index < 0:
			next_index = running_positions.size() - 1
	current_path_index = next_index
	#print("team: ", team,  " next index: ", current_path_index)
	current_waypoint = running_positions[current_path_index].global_position

		
func handle_going_away():
	var speed
	if status.boost > 0:
		speed = attributes.sprint_speed
		status.boost = status.boost - 0.25
	else:
		speed = attributes.speed
	var move_direction: Vector2
	move_direction = global_position.direction_to(rest_position)
	velocity = move_direction * speed
	move_and_slide()
	
	if global_position.distance_to(rest_position) <= 1:
		current_behavior = "deciding"
		current_waypoint = Vector2.ZERO
		has_arrived = true
		
		velocity = Vector2.ZERO

func find_closest_position_index(position: Vector2) -> int:
	var closest_index = 0
	var closest_distance = INF
	for i in running_positions.size():
		var dist = global_position.distance_to(running_positions[i].global_position)
		if dist < closest_distance:
			closest_distance = dist
			closest_index = i
	return closest_index
	
func calculate_clockwise_distance(from: int, to: int) -> int:
	if to >= from:
		return to - from
	else:
		return running_positions.size() - from + to

func calculate_counter_distance(from: int, to: int) -> int:
	if from >= to:
		return from - to
	else:
		return running_positions.size() + from - to
		

func get_random_chill_target() -> Vector2:
	var random_offset = Vector2(
		randf_range(chill_area_min.x, chill_area_max.x),
		randf_range(chill_area_min.y, chill_area_max.y)
	)
	var random_target = rest_position + random_offset
	return Vector2(
		clamp(random_target.x, rest_position.x + chill_area_min.x, rest_position.x + chill_area_max.x),
		clamp(random_target.y, rest_position.y + chill_area_min.y, rest_position.y + chill_area_max.y)
	)
	
func check_chill_state():
	if randf() < 0.3 * attributes.reactions:
		var my_index = find_closest_position_index(global_position)
		var opp_index = find_closest_position_index(opp_pitcher.global_position)
		var current_distance = min(
			calculate_clockwise_distance(opp_index, my_index),
			calculate_counter_distance(opp_index, my_index)
		)
		if current_distance < running_positions.size() * 0.1:
			if randf() < 0.8 * attributes.toughness:
				flee()
				
func set_groove():
	status.groove = attributes.confidence
	
func find_groove(effect: float):
	status.groove = status.groove + effect
	if status.groove > attributes.confidence:
		status.groove = attributes.confidence
	elif status.groove < 0:
		status.groove = 0

func handle_powerbar():
	powerbar.minPower = min_power
	powerbar.maxPower = ball.pitching_max_speed
	powerbar.maxCurve = 2.0 #theoretical maximum
	powerbar.global_position = global_position + Vector2(0, 0)
	powerbar.turn(aim_direction)
	powerbar.bend(current_curve)
	powerbar.stretch(current_power)
	#powerbar.color(current_variance)
