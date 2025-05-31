extends Player
class_name Reworked_Pitcher

signal ball_pitched(power: float, spin: float, direction: Vector2, position: Vector2)
signal special_pitched(position: Vector2)
# Pitching Controls
var true_max_power = 1200 * attributes.power/100 #maximum possible power at 100% energy
@export var max_power: float = true_max_power * status.energy
@export var min_power: float = 100
@export var max_curve: float = 2.0 # radians/second
@export var curve_step: float = 0.1

# Special Pitches
@export var special_pitch_cooldowns: Array[float] = [10.0, 15.0] # Seconds
@export var special_pitch_names: Array[String] = ["fake_curve", "zig_zag"]
var special_pitch_timers: Array[float] = [0.0, 0.0]
var special_pitch_available: Array[bool] = [false, false]

# AI Memory
var successful_pitches: Array[Dictionary] = []
var last_pitch_type: String = ""
var oppGoal: Vector2
var leftWall
var rightWall

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
var hand_offset: float = 15.0 #how far to move the ball in the X to keep it from colliding
var aim_max_angle : float = 100
var aim_increment: float = 2
var target: Vector2
var field_type: String = "road"
var has_pitched: bool = false


# Nodes TODO
#var aim_arrow = $AimArrow
#var power_meter = $PowerMeter
#var curve_indicator = $CurveIndicator

func _ready():
	super._ready()
	position_type = "pitcher"
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
	if has_pitched:
		go_away()
	if is_controlling_player and is_aiming:
		_handle_pitch_controls()
		variance_timer()
	elif not is_controlling_player and has_ball:
		random_variance()
		handle_ai_pitch_decision()
	else:
		go_away()
	#else:
		#if team == 1:
			#print(str(is_controlling_player) + " and " +str(is_aiming))

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

func handle_ai_pitch_decision():
	# Wait a moment to simulate "wind up" time
	await get_tree().create_timer(0.5).timeout
	
	var pitch_to_use = select_ai_pitch()
	execute_pitch(pitch_to_use)

func select_ai_pitch() -> String:
	# Check special pitches first
	for i in special_pitch_available.size():
		if special_pitch_available[i]:
			return special_pitch_names[i]
	
	# Then check successful pitches
	if not successful_pitches.is_empty() and randf() < 0.7: # 70% chance to reuse
		var pitch = successful_pitches.pick_random()
		return pitch["type"]
	
	# Default to random normal pitch
	return "normal"

func execute_pitch(pitch_type: String):
	is_aiming = false
	last_pitch_type = pitch_type
	var ball_position = Vector2(global_position.x + hand_offset, global_position.y)
	match pitch_type:
		"normal":
			perform_normal_pitch()
			#ball_pitched.emit(current_power, current_curve, aim_direction, ball_position)
		"fake_curve":
			perform_fake_curve_pitch()
			special_pitched.emit(ball_position)
		"zig_zag":
			perform_zig_zag_pitch()
			special_pitched.emit(ball_position)
		"knuckler":
			perform_knuckler_pitch()
			special_pitched.emit(ball_position)
		"bouncer":
			perform_bouncer_pitch()
			special_pitched.emit(ball_position)
	
	# Handle special pitch cooldown
	var sp_index = special_pitch_names.find(pitch_type)
	if sp_index >= 0:
		special_pitch_available[sp_index] = false
		special_pitch_timers[sp_index] = special_pitch_cooldowns[sp_index] * (1.2 - (attributes.confidence / 100.0))

#no0rmal pitch curves
func perform_normal_pitch():
	status.energy = status.energy - (10 - attributes.endurance/10) #more endurance, less energy loss
	
	# AI adds some randomness if not player controlled
	if not is_controlling_player:
		var power_variation = randf_range(0.8, 1.2)
		var curve_variation = randf_range(0.5, 1.5)
		
		# Try to bank shots off walls
		if randf() < 0.4: # 40% chance to try bank shot
			var wall_position = get_best_bank_angle()
			aim_direction = (wall_position - ball.global_position).normalized()
			curve_variation = sign(curve_variation) * max_curve * 0.8
			var huck = (current_power * power_variation) * aim_direction
			ball_pitched.emit(huck,  current_curve * curve_variation)
			#ball.apply_pitch(aim_direction * current_power * power_variation, current_curve * curve_variation, aim_direction, global_position)
	else:
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

func perform_fake_curve_pitch():
	var curve_dir = 1.0 if randf() > 0.5 else -1.0
	var initial_curve = curve_dir * max_curve * 1.2
	
	# Create a trajectory that starts curving then goes straight
	var trajectory = Curve2D.new()
	var start_pos = ball.global_position
	var mid_pos = start_pos + aim_direction * 300
	var end_pos = start_pos + aim_direction * 1500
	
	# Strong initial curve
	trajectory.add_point(start_pos, Vector2.ZERO, aim_direction.rotated(initial_curve) * 500)
	trajectory.add_point(mid_pos)
	
	# Then straight
	trajectory.add_point(end_pos, aim_direction * 800)
	
	ball.set_special_trajectory(trajectory)

func perform_zig_zag_pitch():
	var trajectory = Curve2D.new()
	var start_pos = self.global_position
	var zig_dir = aim_direction.rotated(PI/2) # 90 degree turn
	var zag_dir = aim_direction.rotated(-PI/2) # -90 degree turn
	
	# Create zig-zag path
	trajectory.add_point(start_pos)
	trajectory.add_point(start_pos + zig_dir * 200)
	trajectory.add_point(start_pos + zig_dir * 200 + aim_direction * 300)
	trajectory.add_point(start_pos + zag_dir * 200 + aim_direction * 600)
	trajectory.add_point(start_pos + aim_direction * 1000)
	
	ball.set_special_trajectory(trajectory)

func perform_knuckler_pitch():
	var power = current_power * (attributes.power / 100.0)
	
	# Apply random left/right curve changes
	ball.apply_pitch(aim_direction * power, max_curve)
	ball.current_curve = max_curve
	
	# Add periodic curve reversal
	var tween = create_tween()
	tween.set_loops(4) # Will reverse direction 4 times
	tween.tween_property(ball, "current_curve", -max_curve, 0.15)
	tween.tween_property(ball, "current_curve", max_curve, 0.15)

func perform_bouncer_pitch():
	var wall = get_closest_wall()
	var reflect_dir = (wall.position - ball.global_position).normalized().bounce(wall.normal)
	
	var trajectory = Curve2D.new()
	var start_pos = ball.global_position
	
	# Create bounce path (3 bounces)
	for i in 3:
		var next_pos = start_pos + reflect_dir * 400
		trajectory.add_point(start_pos)
		trajectory.add_point(next_pos)
		start_pos = next_pos
		reflect_dir = reflect_dir.bounce(wall.normal) # Bounce again
	
	ball.set_special_trajectory(trajectory)

func get_best_bank_angle() -> Vector2:
	# AI calculates optimal bank shot off walls
	var goal_pos = oppGoal
	
	# Get all wall segments
	var walls = [leftWall, rightWall]
	var best_wall = walls[0]
	var best_angle = 0.0
	var best_score = 0.0
	
	for wall in walls:
		var reflect_dir = (ball.global_position - wall.global_position).normalized().bounce(wall.normal)
		var shot_angle = reflect_dir.angle_to((goal_pos - wall.global_position).normalized())
		var angle_score = 1.0 - abs(shot_angle) / PI # Closer to 0 is better
		
		if angle_score > best_score:
			best_score = angle_score
			best_wall = wall
	
	return best_wall.position

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
		# Add pitch to successful pitches if not already there
		var already_exists = false
		for pitch in successful_pitches:
			if pitch["type"] == last_pitch_type:
				already_exists = true
				break
		
		if not already_exists:
			successful_pitches.append({
				"type": last_pitch_type,
				"power": current_power,
				"curve": current_curve,
				"count": 1
			})
		else:
			var pitch = successful_pitches.find(last_pitch_type)
			pitch.count += 1
			
func get_closest_wall():
	if bio.leftHanded:
		return rightWall
	else:
		return leftWall

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
	has_ball = false
	is_aiming = true
	is_controlling_player = false
	
func go_away():
	global_position = Vector2(-1000,-1000)
	is_controlling_player = false
	has_ball = false
	can_move = false
	
#TODO: change this for different fields
func prepare_target_position():
	target = Vector2(0,0)
	print("target position: " + str(target))
