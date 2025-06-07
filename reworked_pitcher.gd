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
var hand_offset: float = 15.0 #how far to move the ball in the X to keep it from colliding
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
	elif !can_pitch:
		increment_pitch_time()
	elif not is_controlling_player and has_ball:
		random_variance()
		handle_ai_pitch_decision()
	else:
		go_away()
	#else:
		#if team == 1:
			#print(str(is_controlling_player) + " and " +str(is_aiming))

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
	# Wait a moment to simulate "wind up" time
	await get_tree().create_timer(0.5).timeout
	
	if false: #TODO: determine if can throw special pitch
		pass
		#TODO: throw a special pitch
	elif len(successful_pitches) > 0:
		pass
		#TODO: decide how often to use an already used pitch
	else:
		#TODO: change for different field types
		var x = randf_range(-60,60)
		var y = randf_range(-50, 75)
		var current_target = Vector2(x, y)
		if status.energy > 50: #high energy, high power
			current_power = randf_range(attributes.power * 2, attributes.power * 3) * 4 #792-1188 at 99; 400-600 at 50
			status.energy = status.energy - ((100 - attributes.endurance) * 5)
		else: #low energy, lower power
			current_power = randf_range(attributes.power , attributes.power * 2) * 4#396-792 at 99, 200-400 at 50
			status.energy = status.energy - ((100 - attributes.endurance) * 2)
		var weight_chance = randi_range(0, 10)
		#lexx likely to throw wildly curved pitches
		if weight_chance <= 6: #60% chance
			current_curve = randf_range(0 -max_curve/4, max_curve/4)
		elif weight_chance <= 9: #30% chance
			current_curve = randf_range(0-max_curve/2, max_curve/2)
		else: #10% chance
			current_curve = randf_range(0-max_curve, max_curve)
		lastCurve = current_curve
		lastPower = current_power
		lastTarget = current_target
		perform_ai_normal_pitch(current_target)
	#execute_pitch(pitch_to_use)


func execute_pitch(pitch_type: String):
	is_aiming = false
	ball.last_hit_by = self
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

func perform_ai_normal_pitch(target):
	print("robot launching ball")
	aim_direction = global_position.direction_to(target).normalized()
	var varied_direction = aim_direction.rotated(current_variance * variance_factor)   
	var huck = current_power * varied_direction
	print("aim with variance: " + str(aim_direction))
	release_ball()
	ball_pitched.emit(huck, current_curve)

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
	
	ball.be_special_pitched(current_power, trajectory, global_position)
	release_ball()

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
	
	ball.be_special_pitched(current_power, trajectory, global_position)
	release_ball()

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
	
	release_ball()
	
func find_wall_normal(wall:StaticBody2D) -> Vector2:
	if wall.global_position.x < global_position.x:
		return Vector2.RIGHT
	else:
		return Vector2.LEFT
	

func perform_bouncer_pitch():
	var wall = get_closest_wall()
	var wall_normal
	wall_normal = find_wall_normal(wall)
		
	var reflect_dir = (wall.global_position - ball.global_position).normalized().bounce(wall_normal)
	
	var trajectory = Curve2D.new()
	var start_pos = ball.global_position
	# Create bounce path (3 bounces)
	for i in 3:
		var next_pos = start_pos + reflect_dir * 400
		trajectory.add_point(start_pos)
		trajectory.add_point(next_pos)
		start_pos = next_pos
		reflect_dir = reflect_dir.bounce(wall_normal) # Bounce again
	release_ball()
	ball.be_special_pitched(current_power, trajectory, global_position)

func get_best_bank_angle() -> Vector2:
	# AI calculates optimal bank shot off walls
	var goal_pos = oppGoal
	
	# Get all wall segments
	var walls = [left_wall, right_wall]
	var best_wall = walls[0]
	var best_angle = 0.0
	var best_score = 0.0
	
	for wall in walls:
		var wall_normal = find_wall_normal(wall)
		var reflect_dir = (ball.global_position - wall.global_position).normalized().bounce(wall_normal)
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
	is_aiming = true
	is_controlling_player = false
	ball.last_hit_by = self
	
func go_away():
	global_position = Vector2(-1000,-1000)
	is_controlling_player = false
	has_ball = false
	can_move = false
	
#TODO: change this for different fields
func prepare_target_position():
	target = Vector2(0,0)
	print("target position: " + str(target))
