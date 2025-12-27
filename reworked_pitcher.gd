extends Player
class_name Reworked_Pitcher

signal ball_pitched(power: float, spin: float, direction: Vector2, position: Vector2)
signal special_pitched(direction: Vector2, power: float, curves: Array[float], frames: Array[int], pitch_type: String, power_curve: bool)

# Pitching Controls
var true_max_power = 5.204 * (get_buffed_attribute("power") + get_buffed_attribute("throwing"))  - 40.408 #maximum possible power at 100% energy, 990 at 99 throwing and power, 480 at 50 throwing and power
@export var max_power: float = true_max_power * status.energy/100
@export var min_power: float = 200
@export var max_curve: float = 2.0 # radians/second
@export var curve_step: float = 0.1
@onready var powerbar = $UI/PowerBar

# AI Memory and Decision Making
var successful_pitches: Array[Dictionary] = []
var pitch_success_threshold: int = 3 # How many times a pitch needs to succeed to be "favored"
var favor_successful_chance: float = 0.3 # 30% chance to use a favored pitch type
var most_recent_pitch #dictionary of the data from current pitch
var buddyK
var buddyLG
var buddyRG
var buddyLF
var buddyRF

# Movement constants
const MAX_DIRECTION_CHANGES := 3 #double juke and change
const REACTION_CHECK_INTERVAL := 2.0
const CLOSE_DISTANCE_THRESHOLD := 0.45

var oppGoal: Vector2 #center of opposing goal
var left_wall
var right_wall
var lastTarget: Vector2
var lastPower: float
var lastCurve: float

# Pitch State
var current_power: float = 250
var current_curve: float = 0.0
var is_aiming: bool = false
var aim_direction: Vector2 = Vector2(0,1)
var has_ball: bool = false
var increasing := true
var pause_counter: int = 0
var variance_factor = 0.5 * (100 - get_buffed_attribute("accuracy"))/200 #23.5% to 0.0025% effect
var current_variance = 0 #ranges from -100 to 100, then multiplied by variance factor
var variance_increment = 3
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
@export var rest_position: Vector2 = Vector2(-1000, -1000)
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
var direction_changes_this_pitch: int = 0  # Tracks direction changes for the current pitch
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
var is_faceoff_recover: bool = false
var faceoff_waiting_for_ball: bool = false
var must_go_to_rest_first: bool = true

var current_move_axis: String = "x" # or "y" - tracks which axis we're currently moving on
var move_sequence: Array[Vector2] = [] # Stores sequence of straight moves to reach waypoint
var current_move_index: int = 0 # Current move in sequence
var using_grid_movement: bool = true # Whether to use grid-based movement
var last_grid_position: Vector2 = Vector2.ZERO

var discipline_failures: int = 0
var is_cutting_corner: bool = false
var north_position: Vector2 = Vector2.ZERO
var south_position: Vector2 = Vector2.ZERO

# New state for transitioning to track
var going_to_track: bool = false
var track_target_corner: Vector2 = Vector2.ZERO

func _ready():
	super._ready()
	current_behavior = "waiting"
	collision_mask = 0b0000  # Collide with nothing
	position_type = "pitcher"
	max_curve = 2.0 * (get_buffed_attribute("focus") + get_buffed_attribute("throwing"))/200
	restore_behaviors()
	powerbar.currentPower = current_power
	powerbar.maxPower = true_max_power
	if bio.leftHanded:
		hand_offset = hand_offset * -1
	last_grid_position = global_position
		
func restore_behaviors():
	behaviors = ["pitching", "going_away", "going_to_track", "deciding", "waiting", "chilling", "chasing", "fleeing", "fighting", "faceoff", "faceoff_recover"]

func _physics_process(delta):
	super._physics_process(delta)
	if north_position == Vector2.ZERO:
		if team == 2:
			north_position = rest_position
		else:
			if opp_pitcher:
				north_position = opp_pitcher.rest_position
	elif south_position == Vector2.ZERO:
		if team == 1:
			south_position = rest_position
		else:
			if opp_pitcher:
				south_position = opp_pitcher.rest_position
	await ball
	update_special_pitch_availability()
	powerbar.visible = false
	
	# Safety check - if pitcher has pitched but hasn't transitioned to going_away
	if has_pitched and current_behavior != "going_away" and current_behavior != "going_to_track" and current_behavior != "deciding" and current_behavior != "fighting" and current_behavior != "chasing" and current_behavior != "fleeing" and current_behavior != "chilling" and current_behavior != "tracking" and current_behavior != "faceoff_recover" and current_behavior != "faceoff":
		print(bio.last_name + " forgot to go away! Forcing transition.")
		go_away()
	
	if Input.is_action_pressed("pitch"):
		human_ready = true
		prepare_ai_to_pitch()
	
	# Handle different behaviors
	if current_behavior == "waiting":
		handle_waiting()
	elif current_behavior == "faceoff":
		velocity = Vector2.ZERO
		can_move = false
		move_sequence = []
	elif current_behavior == "deciding":
		handle_deciding()
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
	elif current_behavior == "going_to_track":
		go_to_track()
	elif current_behavior == "faceoff_recover":
		faceoff_recover()
	
	# Handle pitching states
	if is_controlling_player and is_aiming and current_behavior != "faceoff" and current_behavior != "faceoff_recover":
		current_behavior = "pitching"
		has_arrived = false
		powerbar.visible = true
		current_waypoint = Vector2.ZERO
		velocity = Vector2.ZERO
		move_sequence = []
		_handle_pitch_controls()
		variance_timer()
		handle_powerbar()
	elif !can_pitch:
		increment_pitch_time()
	elif not is_controlling_player and has_ball:
		has_arrived = false
		random_variance()
		handle_ai_pitch_decision()

func handle_waiting():
	has_arrived = false
	has_attacked = false
	current_waypoint = Vector2.ZERO
	move_sequence = []
	# Non-throwing pitcher waits for throwing pitcher to reach track
	if opp_pitcher and opp_pitcher.current_behavior == "deciding" and !has_made_first_move:
		# Opponent has reached the track, now it's our turn
		current_behavior = "going_to_track"
		go_to_track_start()

func handle_deciding():
	current_waypoint = Vector2.ZERO
	move_sequence = []
	if !opp_pitcher or opp_pitcher.has_arrived == false:
		can_move = false
		return
	else:
		can_move = true
	velocity = Vector2.ZERO
	if has_arrived and opp_pitcher.has_arrived == true:
		fight_or_flight()
		
func check_human_input():
	if team == 1:
		if Input.is_action_just_pressed("pitcher_chill"):
			current_behavior = "chilling"
		elif Input.is_action_just_pressed("pitcher_chase"):
			current_behavior = "chasing"
		elif Input.is_action_just_pressed("pitcher_flee"):
			current_behavior = "tracking"
		elif Input.is_action_just_pressed("pitcher_turn"):
			# UNLIMITED DIRECTION CHANGES FOR HUMAN PLAYERS - BUG FIX #1
			moving_clockwise = !moving_clockwise
			direction_changes_this_pitch += 1
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
	generate_horizontal_first_path(current_waypoint)

func increment_pitch_time():
	current_frame = current_frame + 1
	if current_frame > pitch_goal:
		can_pitch = true
		
func faceoff():
	var open_passes = [false, false, false, false, false] #LG, K, RG, LF, RF
	var teammates = [buddyLG, buddyK, buddyRG, buddyLF, buddyRF]
	
	# Check which teammates have open passing lanes
	for i in teammates.size():
		if teammates[i]:
			open_passes[i] = check_pass_open(teammates[i])
	
	var distance_to_goal = global_position.distance_squared_to(oppGoal)
	var max_shooting_distance = 200000 # Adjust based on your field size
	var distance_factor = clamp(1.0 - (distance_to_goal / max_shooting_distance), 0.0, 1.0)
	var shoot_weight = distance_factor * (get_buffed_attribute("aggression") / 100.0) * (status.groove / 100.0)
	
	var wants_forward = randf_range(0, 120) < get_buffed_attribute("aggression")
	var weights = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0] #LG, K, RG, LF, RF, shoot
	
	if wants_forward:
		if bio.leftHanded:
			weights = [0.3, 0.2, 0.1, 0.6, 0.9, shoot_weight]
		else:
			weights = [0.1, 0.2, 0.3, 0.9, 0.6, shoot_weight]
	else:
		if bio.leftHanded:
			weights = [0.6, 0.5, 0.4, 0.3, 0.2, shoot_weight / 2]
		else:
			weights = [0.4, 0.5, 0.6, 0.2, 0.3, shoot_weight / 2]
	
	# Zero out weights for closed passing lanes
	for i in open_passes.size():
		if !open_passes[i]:
			weights[i] = 0.0
	
	# Calculate sum of weights
	var sum = 0.0
	for weight in weights:
		sum += weight
	
	# If no options available, just shoot
	if sum == 0:
		return select_shooting_target()
	
	# Pick target based on weighted random
	var rand = randf_range(0, sum)
	var cumulative = 0.0
	
	for i in weights.size():
		cumulative += weights[i]
		if rand <= cumulative:
			if i == 5: # Shoot option
				return select_shooting_target()
			else: # Pass to teammate
				return teammates[i].global_position
	
	# Fallback: shoot
	return select_shooting_target()

func select_shooting_target() -> Vector2:
	# Assuming oppGoal has left_post and right_post members or you calculate them
	# For now, we'll estimate the goal posts based on goal position
	var goal_width = 100 # Adjust based on your goal size
	var left_post = oppGoal + Vector2(-goal_width / 2, 0)
	var right_post = oppGoal + Vector2(goal_width / 2, 0)
	
	# Don't always shoot dead center - vary the target
	var accuracy_factor = get_buffed_attribute("accuracy") / 100.0
	var randomness = (1.0 - accuracy_factor) * 0.5
	var target_ratio = randf_range(0.3 - randomness, 0.7 + randomness)
	
	return left_post.lerp(right_post, target_ratio)
	
func check_pass_open(player: Player) -> bool:
	if !player:
		return false
	
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [self, ball] # Don't collide with self or ball
	query.collision_mask = 0b0001 # Assuming layer 1 is for players/obstacles
	
	var result = space.intersect_ray(query)
	
	# If we hit something other than the target player, path is blocked
	if result and result.collider != player:
		return false
	
	return true

func handle_discipline_failure_choice() -> String:
	var aggression = get_buffed_attribute("aggression")
	var discipline = get_buffed_attribute("discipline")
	
	# Calculate chance to go for ball vs attack pitcher
	# Higher aggression increases chance to attack pitcher
	# Lower discipline increases chance to make a mistake (go for ball when shouldn't)
	var go_for_ball_chance = (100 - discipline) * 0.6  # 0-60% chance
	var attack_pitcher_chance = aggression * 0.8       # 0-80% chance
	
	var total = go_for_ball_chance + attack_pitcher_chance
	if total == 0:
		return "neither"
	
	var roll = randf_range(0, total)
	
	if roll < go_for_ball_chance:
		return "ball"
	else:
		return "pitcher"

func faceoff_recover():
	is_faceoff_recover = true
	can_move = true
	
	#check discipline for immediate fighting or ball chasing
	var discipline_check_1 = randi_range(0, 100)
	var discipline_threshold = get_buffed_attribute("discipline")
	
	if discipline_check_1 > discipline_threshold:
		var discipline_check_2 = randi_range(0, 100)
		if discipline_check_2 > discipline_threshold:
			var aggression_check = randi_range(0, 100)
			var aggression_threshold = get_buffed_attribute("aggression")
			
			if aggression_check > aggression_threshold: #we go ball
				print(bio.last_name + " failed discipline twice! Going for the ball")
				if ball and global_position.distance_to(ball.global_position) < 30:
					target = select_shooting_target() #shoot at the goal
					aim_direction = global_position.direction_to(target).normalized()
					var ball_direction = global_position.direction_to(ball.global_position).normalized()
					var sprint_speed = get_buffed_attribute("sprint_speed")
					var speed = get_buffed_attribute("speed")
					if status.boost > 0:
						status.boost = max(0, status.boost - 1.0)
						speed = get_buffed_attribute("sprint_speed")
					velocity = ball_direction * speed
					move_and_slide()
					if global_position.distance_to(ball.global_position) < 20:
						print(bio.last_name + " touched the ball, now exiting the field")
						var left_distance = abs(global_position.x - left_wall.global_position.x)
						var right_distance = abs(global_position.x - right_wall.global_position.x)
						var exit_target: Vector2
						if left_distance < right_distance:
							exit_target = Vector2(left_wall.global_position.x - 100, global_position.y - 100)
							print(bio.last_name + " exiting left (closest sideline)")
						else:
							exit_target = Vector2(right_wall.global_position.x + 100, global_position.y - 100)
							print(bio.last_name + " exiting right (closest sideline)")
						current_behavior = "going_away"
						current_waypoint = exit_target
						velocity = global_position.direction_to(exit_target) * get_buffed_attribute("sprint_speed")
						move_and_slide()
						return
				else:
					print(bio.last_name + " can't reach ball, exiting to closest sideline")
					
			else: #we're grumpy so we go man
				if opp_pitcher and global_position.distance_to(opp_pitcher.global_position) < 100:
					print(bio.last_name + " failed discipline twice! Attacking opposing pitcher!")
					var attack_direction = global_position.direction_to(opp_pitcher.global_position).normalized()
					var speed = get_buffed_attribute("speed")
					if status.boost > 0:
						speed =get_buffed_attribute("sprint_speed")
						status.boost = max(0, status.boost - 1.0)
					
					velocity = attack_direction * speed
					move_and_slide()
					if global_position.distance_to(opp_pitcher.global_position) < 10:
						current_behavior = "fighting"
						has_arrived = true
						is_faceoff_recover = false
						print(bio.last_name + " is fighting on the field, what a psycho")
						return
				else:
					print(bio.last_name + " opponent too far, exiting normally")
	var faceoff_pos = ball.global_position if ball else global_position
	var exit_direction: Vector2 = Vector2.ZERO
	
	# Check if it's a side faceoff or centered offensive faceoff
	var is_left_faceoff = faceoff_pos.x < 0  # Near left sideline
	var is_right_faceoff = faceoff_pos.x > 0  # Near right sideline
	var rand_y = randi_range(-0.2, 0.2) #some variance instead of just going straight left or right
	if randi_range(0,100) < get_buffed_attribute("positioning"):
		rand_y = 0 #if we have good positioning, just get the hell off
	if is_left_faceoff:
		exit_direction = Vector2(-1, rand_y)
	elif is_right_faceoff:
		exit_direction = Vector2(1, rand_y)
	else:
		if randf() < 0.5:
			exit_direction = Vector2(-1, rand_y)
		else:
			exit_direction = Vector2(1, rand_y)
		if current_behavior == "chasing": 
			# Small chance to switch direction based on opponent position
			if opp_pitcher and randi_range(0,100) < get_buffed_attribute("reactions"):
				var opp_direction = (opp_pitcher.global_position - global_position).normalized()
				if opp_direction.dot(exit_direction) < 0:
					exit_direction = -exit_direction
					print(bio.last_name + ": Switching direction to chase opponent")
	var speed = get_buffed_attribute("sprint_speed") if status.boost > 0 else get_buffed_attribute("speed")
	if status.boost > 0:
		speed = get_buffed_attribute("sprint_speed")
		status.boost = max(0, status.boost - 0.5)
	velocity = exit_direction * speed
	move_and_slide()
	

	if is_off_field():
		is_faceoff_recover = false
		var behavior_roll = randf_range(0, 100)
		var flee_threshold = scrapping["flee"]
		var chill_threshold = flee_threshold + scrapping["chill"]
		var fight_threshold = chill_threshold + scrapping["fight"]
		
		var chosen_behavior = ""
		if behavior_roll < flee_threshold:
			chosen_behavior = "fleeing"
		elif behavior_roll < chill_threshold:
			chosen_behavior = "chilling"
		elif behavior_roll < fight_threshold:
			chosen_behavior = "chasing"
		else:
			chosen_behavior = "tracking"
		if chosen_behavior == "chasing" and opp_pitcher and !is_off_field_at_position(opp_pitcher.global_position):
			var my_closest = find_closest_position_index(global_position)
			var opp_closest = find_closest_position_index(opp_pitcher.global_position)
			var clockwise_dist = calculate_clockwise_distance(my_closest, opp_closest)
			var counter_dist = calculate_counter_distance(my_closest, opp_closest)
			
			moving_clockwise = clockwise_dist < counter_dist
			
			if moving_clockwise:
				var next_clock = (my_closest + 1) % running_positions.size()
				var next_counter = (my_closest - 1 + running_positions.size()) % running_positions.size()
				legal_first_moves = [next_clock, next_counter]
			else:
				var next_counter = (my_closest - 1 + running_positions.size()) % running_positions.size()
				var next_clock = (my_closest + 1) % running_positions.size()
				legal_first_moves = [next_counter, next_clock]
			
			current_waypoint = running_positions[my_closest].global_position
			current_path_index = my_closest
			velocity = Vector2.ZERO
			
			# Start with chilling to get oriented, then transition to chase
			current_behavior = "chilling"
			current_chill_target = get_random_chill_target()
			
			# After a brief chill, start chasing
			var chill_timer = Timer.new()
			chill_timer.wait_time = 1.0  # Chill for 1 second
			chill_timer.one_shot = true
			chill_timer.timeout.connect(func():
				if current_behavior == "chilling":
					current_behavior = "chasing"
					initialize_chase()
				chill_timer.queue_free()
			)
			add_child(chill_timer)
			chill_timer.start()
		else:
			if chosen_behavior == "fleeing":
				current_behavior = "fleeing"
				is_fleeing = true
				is_chasing = false
				direction_changes = 0
				direction_changes_this_pitch = 0
				initialize_waypoints()
			elif chosen_behavior == "chilling":
				current_behavior = "chilling"
				current_chill_target = get_random_chill_target()
			elif chosen_behavior == "chasing":
				current_behavior = "chasing"
				initialize_chase()
				direction_changes = 0
				direction_changes_this_pitch = 0
				initialize_waypoints()
			else:  # tracking
				current_behavior = "tracking"
				initialize_waypoints()

func generate_grid_path_to_waypoint():
	move_sequence = []
	current_move_index = 0
	
	if current_waypoint == Vector2.ZERO:
		return
	
	var start = global_position
	var target = current_waypoint
	
	# Calculate differences
	var dx = target.x - start.x
	var dy = target.y - start.y
	
	# Determine movement order (random or based on largest difference)
	var move_x_first = abs(dx) > abs(dy) if randf() > 0.5 else randf() < 0.5
	
	if move_x_first:
		# Move horizontally first
		if abs(dx) > 5:  # Only move if significant distance
			var x_move = Vector2(target.x, start.y)
			move_sequence.append(x_move)
		
		# Then move vertically
		if abs(dy) > 5:  # Only move if significant distance
			var y_move = Vector2(target.x, target.y)
			move_sequence.append(y_move)
	else:
		# Move vertically first
		if abs(dy) > 5:  # Only move if significant distance
			var y_move = Vector2(start.x, target.y)
			move_sequence.append(y_move)
		
		# Then move horizontally
		if abs(dx) > 5:  # Only move if significant distance
			var x_move = Vector2(target.x, target.y)
			move_sequence.append(x_move)
	
	# If no movement needed (already at target), clear sequence
	if move_sequence.size() == 0:
		move_sequence = []

func generate_horizontal_first_path(target_position: Vector2):
	move_sequence = []
	current_move_index = 0
	
	if target_position == Vector2.ZERO:
		return
	
	var start = global_position
	
	# Always move horizontally first for initial track movement
	var horizontal_target = Vector2(target_position.x, start.y)
	var vertical_target = Vector2(target_position.x, target_position.y)
	
	# Only add moves if we actually need to move
	if abs(start.x - target_position.x) > 5:
		move_sequence.append(horizontal_target)
	
	if abs(start.y - target_position.y) > 5:
		move_sequence.append(vertical_target)
	
	# If we don't need to move at all, clear the sequence
	if move_sequence.size() == 0:
		move_sequence = []

func move_along_grid():
	if move_sequence.size() == 0 or current_move_index >= move_sequence.size():
		return true  # Path completed
	
	var target_point = move_sequence[current_move_index]
	var direction = target_point - global_position
	
	# Only move in cardinal directions
	if abs(direction.x) > abs(direction.y):
		# Move horizontally
		direction = Vector2(1 if direction.x > 0 else -1, 0)
	else:
		# Move vertically
		direction = Vector2(0, 1 if direction.y > 0 else -1)
	
	var speed = get_buffed_attribute("sprint_speed") if status.boost > 0 else get_buffed_attribute("speed")
	velocity = direction * speed
	move_and_slide()
	
	# Check if we've reached the current grid point with better precision
	var distance_to_target = global_position.distance_to(target_point)
	if distance_to_target < 15:
		current_move_index += 1
		return false
	
	# Also check if we overshot the target
	var original_distance = last_grid_position.distance_to(target_point)
	var current_distance = global_position.distance_to(target_point)
	
	if current_distance > original_distance and distance_to_target < 30:
		# We overshot, but we're close enough
		current_move_index += 1
		return false
	
	# Update last grid position
	last_grid_position = global_position
	
	return false  # Path not completed

func predict_opponent_exit() -> Vector2:
	if !opp_pitcher or !running_positions or running_positions.size() == 0:
		return Vector2.ZERO
	
	var opp_closest = find_closest_position_index(opp_pitcher.global_position)
	
	# Predict which direction they'll go based on their position and velocity
	var opp_vel = opp_pitcher.velocity
	if opp_vel.length() > 10:
		# They're moving, predict based on velocity
		var next_clock_pos = running_positions[(opp_closest + 1) % running_positions.size()].global_position
		var next_counter_pos = running_positions[(opp_closest - 1 + running_positions.size()) % running_positions.size()].global_position
		
		var clock_alignment = opp_vel.normalized().dot((next_clock_pos - opp_pitcher.global_position).normalized())
		var counter_alignment = opp_vel.normalized().dot((next_counter_pos - opp_pitcher.global_position).normalized())
		
		if clock_alignment > counter_alignment:
			return next_clock_pos
		else:
			return next_counter_pos
	else:
		# They're not moving yet, guess based on distance
		var clockwise_dist = calculate_clockwise_distance(opp_closest, find_closest_position_index(global_position))
		var counter_dist = calculate_counter_distance(opp_closest, find_closest_position_index(global_position))
		
		if clockwise_dist < counter_dist:
			return running_positions[(opp_closest + 1) % running_positions.size()].global_position
		else:
			return running_positions[(opp_closest - 1 + running_positions.size()) % running_positions.size()].global_position

func move_toward_waypoint():
	if current_waypoint == Vector2.ZERO:
		# Find the nearest track waypoint and go there horizontally first
		var closest_index = find_closest_position_index(global_position)
		current_waypoint = running_positions[closest_index].global_position
		generate_horizontal_first_path(current_waypoint)
	
	if current_behavior in ["chasing", "fleeing", "tracking"] and using_grid_movement:
		if move_sequence.size() == 0 or current_move_index >= move_sequence.size():
			# Generate new path to waypoint
			generate_horizontal_first_path(current_waypoint)
		
		# Move along grid
		var path_completed = move_along_grid()
		if path_completed:
			# Reached waypoint, advance to next
			advance_waypoints()
	else:
		# Old movement for non-grid behaviors
		var speed = get_buffed_attribute("sprint_speed") if status.boost > 0 else get_buffed_attribute("speed")
		status.boost = max(0, status.boost - 0.25)
		var direction = global_position.direction_to(current_waypoint)
		velocity = direction * speed 
		move_and_slide()

func is_off_field() -> bool:
	var field_bounds = Rect2(left_wall.global_position.x, right_wall.global_position.x, oppGoal.y, 0 - oppGoal.y)
	return !field_bounds.has_point(global_position)

func is_off_field_at_position(pos: Vector2) -> bool:
	var field_bounds = Rect2(left_wall.global_position.x, right_wall.global_position.x, oppGoal.y, 0 - oppGoal.y)
	return !field_bounds.has_point(pos)

func _on_pitch_phase_started():
	status.boost = max(status.boost, 10) 
	has_made_first_move = false
	max_power = true_max_power * status.energy
	is_aiming = true
	current_power = lerp(min_power, max_power, 0.51)
	current_curve = 0.0
	is_chasing = false
	is_fleeing = false
	direction_changes = 0
	direction_changes_this_pitch = 0  # Reset direction changes for new pitch
	pause_counter = 0
	current_behavior = "waiting"
	prepare_target_position()

func _handle_pitch_controls():
	can_move = false
	if target == Vector2.ZERO:
		prepare_target_position()
		aim_direction = global_position.direction_to(target).normalized()
	if Input.is_action_pressed("move_up"):
		current_power = min(max_power, current_power + 10)
	elif Input.is_action_pressed("move_down"):
		current_power = max(min_power, current_power - 10)
	if Input.is_action_pressed("increase_spin"):
		current_curve = min(max_curve, current_curve + curve_step)
	elif Input.is_action_pressed("decrease_spin"):
		current_curve = max(0-max_curve, current_curve - curve_step)
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
	var max_groove = get_buffed_attribute("confidence")
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
	
	
	var x_coord: float = randf_range(left_wall.global_position.x, right_wall.global_position.x)
	var y_coord: float = randf_range(global_position.y/2, oppGoal.y)
	
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
	
	var aggression_factor = get_buffed_attribute("aggression") / 100.0
	var energy_factor = status.energy / 100.0
	
	if energy_factor > 0.5:
		current_power = lerp((get_buffed_attribute("power")* get_buffed_attribute("throwing")/100) * 2, (get_buffed_attribute("power")* get_buffed_attribute("throwing")/100) * 4, aggression_factor) * 4
		status.energy -= (100 - get_buffed_attribute("endurance")) * 5
	else:
		current_power = randf_range((get_buffed_attribute("power")* get_buffed_attribute("throwing")/100), (get_buffed_attribute("power")* get_buffed_attribute("throwing")/100) * 2) * 4
		status.energy -= (100 - get_buffed_attribute("endurance")) * 2
	
	var focus_factor = get_buffed_attribute("focus") / 100.0
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
	
	# Call go_away for the AI pitcher after a normal pitch
	go_away()

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
		"changeup":
			perform_changeup_pitch()
		"flutter":
			perform_flutter_pitch()
		"moonball":
			perform_moonball_pitch()
		"stop_go":
			perform_stop_go_pitch()
		"none":
			perform_normal_pitch()
	has_pitched = true
	
	var sp_index = special_pitch_names.find(pitch_type)
	if sp_index >= 0:
		special_pitch_available[sp_index] = false
		if status.groove >= special_pitch_groove[sp_index]:
			special_pitch_available[sp_index] = true
	
	# If this is the AI pitcher, go away immediately
	if !is_controlling_player:
		go_away()

func perform_ai_normal_pitch(point):
	aim_direction = global_position.direction_to(point).normalized()
	var varied_direction = aim_direction.rotated(current_variance * variance_factor)   
	var huck = current_power * varied_direction
	release_ball()
	ball_pitched.emit(huck, current_curve)
	has_pitched = true
	most_recent_pitch = {"pitch_type": "normal", "power": current_power, "curve": current_curve, "direction": aim_direction}

func perform_normal_pitch():
	print("current power: " + str(current_power))
	# Ensure target and aim direction are properly set
	if target == Vector2.ZERO:
		target = global_position + Vector2(0, 0 if field_type != "road" else 100)  # Default direction based on field
		aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - get_buffed_attribute("endurance")/10)
	var varied_direction = aim_direction.normalized()
	varied_direction = varied_direction.rotated(current_variance * variance_factor)   
	if field_type == "road" || field_type == "wide_road":
		if varied_direction.y > 0:
			varied_direction.y = varied_direction.y * -1
	var huck = current_power * varied_direction
	release_ball()
	ball_pitched.emit(huck, current_curve)
	
#starts fast then slows down, mimicing a tricky throw that looks like it will come fast
func perform_changeup_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (5 - get_buffed_attribute("endurance")/20)#not an energy intensive pitch
	var toss_speed = current_power * 0.75
	var change_speed = (149 - get_buffed_attribute("focus"))/100.0 * toss_speed  #50% at 99 focus, 99% at 50 focus
	if change_speed > toss_speed:
		change_speed = toss_speed
	print("toss speed: " + str(toss_speed) + "; change speed: " + str(change_speed))
	var curves: Array[float] = [toss_speed, change_speed, change_speed]
	var frames: Array[int] = [55, 65, 200]
	special_pitched.emit(aim_direction, current_curve, curves, frames, "changeup", true)
	most_recent_pitch = {"pitch_type": "changeup", "power": current_power, "curve": current_curve, "direction": aim_direction}
	release_ball()
	
#fake changeup
func perform_stop_go_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - get_buffed_attribute("endurance")/10)
	var toss_speed = current_power * 0.75
	var change_speed = (149 - get_buffed_attribute("focus"))/100.0 * toss_speed  #50% at 99 focus, 99% at 50 focus
	if change_speed > toss_speed:
		change_speed = toss_speed
	var curves: Array[float] = [toss_speed, change_speed, toss_speed, toss_speed]
	var frames: Array[int] = [50, 55, 75, 300]
	special_pitched.emit(aim_direction, current_curve, curves, frames, "stop_go", true)
	most_recent_pitch = {"pitch_type": "stopgo", "power": current_power, "curve": current_curve, "direction": aim_direction}

#starts slow then speeds up, mimicing a ball that was thrown way up into the air
func perform_moonball_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (5 - get_buffed_attribute("endurance")/20)
	var toss_speed = current_power * (get_buffed_attribute("focus")/100.0) #99% at 99, 50% at 50
	var change_speed = toss_speed * 0.75
	if change_speed > toss_speed:
		change_speed = toss_speed
	var curves: Array[float] = [change_speed, toss_speed, toss_speed]
	var frames: Array[int] = [50, 75, 300]
	special_pitched.emit(aim_direction, current_curve, curves, frames, "moonball", true)
	most_recent_pitch = {"pitch_type": "changeup", "power": current_power, "curve": current_curve, "direction": aim_direction}
	release_ball()
	
#changes speed a lot
func perform_flutter_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - get_buffed_attribute("endurance")/10)
	var toss_speed = current_power * 0.75
	var change_speed = (((149 - get_buffed_attribute("focus"))/100.0 * toss_speed) + toss_speed)/2
	if change_speed > toss_speed:
		change_speed = toss_speed
	var curves: Array[float] = [toss_speed, change_speed, toss_speed, change_speed, toss_speed, change_speed]
	var frames: Array[int] = [20, 40, 60, 80, 100, 120]
	special_pitched.emit(aim_direction, current_curve, curves, frames, "flutter", true)
	most_recent_pitch = {"pitch_type": "changeup", "power": current_power, "curve": current_curve, "direction": aim_direction}
	release_ball()

#looks like it will curve and then straightens out
func perform_fake_curve_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - get_buffed_attribute("endurance")/10)
	var curves: Array[float] = [-2.4, 8, 0.0]
	var frames: Array[int] = [40, 50, 60]
	special_pitched.emit(aim_direction, current_power, curves, frames, "fake_curve")
	most_recent_pitch = {"pitch_type": "fake_curve", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()

#changes direction a bunch of times
func perform_zig_zag_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - get_buffed_attribute("endurance")/10)
	var curves: Array[float] = [0, 100, 0, -100, 0]
	var frames: Array[int] = [20, 22, 42, 44, 200]
	#current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "zig-zag")
	most_recent_pitch = {"pitch_type": "zif-zag", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()
	
#loops around backwards towards a guard
func perform_looper_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - get_buffed_attribute("endurance")/10)
	var curves: Array[float] = [0, 40, 0]
	var frames: Array[int] = [50, 75, 120]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "looper")
	most_recent_pitch = {"pitch_type": "looper", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()

#semi-random
func perform_knuckler_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (5 - get_buffed_attribute("endurance")/20)
	var knuckle = get_buffed_attribute("focus")/5 #10 for 50, 19.8 for 99
	var curves: Array[float] = [0, 0, randf_range(-knuckle, knuckle),randf_range(-knuckle, knuckle), randf_range(-knuckle, knuckle), randf_range(-knuckle, knuckle)]
	var frames: Array[int] = [10, 20, 30, 40, 50, 60]
	special_pitched.emit(aim_direction, current_power, curves, frames, "knuckler")
	most_recent_pitch = {"pitch_type": "knuckler", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()
	
func find_wall_normal(wall:StaticBody2D) -> Vector2:
	if wall.global_position.x < global_position.x:
		return Vector2.RIGHT
	else:
		return Vector2.LEFT

#makes a sudden change, mimicing like it bounced off the ground
func perform_bouncer_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - get_buffed_attribute("endurance")/10)
	var curves: Array[float] = [2.4, -100, 0.0]
	var frames: Array[int] = [40, 42, 60]
	current_power = 300
	special_pitched.emit(aim_direction, current_power, curves, frames, "bouncer")
	most_recent_pitch = {"pitch_type": "bouncer", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()
	
#does a loop-the-loop
func perform_corker_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - get_buffed_attribute("endurance")/10)
	var curves: Array[float] = [0.5, -120, 120, 0.5]
	var frames: Array[int] = [40, 46, 58, 90]
	current_power = 200
	special_pitched.emit(aim_direction, current_power, curves, frames, "corker")
	most_recent_pitch = {"pitch_type": "corker", "power": current_power, "curve": 0, "direction": aim_direction}
	release_ball()

#loops back around onto the keeper
func perform_yoyo_pitch():
	aim_direction = global_position.direction_to(target).normalized()
	status.energy = status.energy - (10 - get_buffed_attribute("endurance")/10)
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
	if status.groove > get_buffed_attribute("confidence"):
		status.groove = get_buffed_attribute("confidence")
	successful_pitches.append(most_recent_pitch)
	pass

func get_closest_wall():
	if bio.leftHanded:
		return right_wall
	else:
		return left_wall

func variance_timer():
	var pause_time = status.groove * 2 #pause at 0 for this amount of frames
	var slow_time = get_buffed_attribute("confidence")/2 #if variance is below this value, slow down the incrementing
	if pause_counter < pause_time:
		pause_counter += 1
		return
	var increment = variance_increment * GlobalSettings.game_speed
	if abs(current_variance) < slow_time:
		increment *= 0.25 
	if increasing:
		if current_variance < 100:
			current_variance = min(current_variance + increment, 100)
		else:
			current_variance = 100
			increasing = false
	else:
		if current_variance > -100:
			current_variance = max(current_variance - increment, -100)
		else:
			current_variance = -100
			increasing = true
			
func random_variance():
	var max_variance = (100 - attributes.accuracy)/2 
	current_variance = randi_range(1,max_variance)

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
	can_move = true 
	has_arrived = false
	has_made_first_move = false
	current_waypoint = rest_position
	move_sequence = []

func prepare_target_position():
	target = Vector2(0,0)

func chase():
	if current_waypoint == Vector2.ZERO:
		# Find the nearest track waypoint and go there horizontally first
		var closest_index = find_closest_position_index(global_position)
		current_waypoint = running_positions[closest_index].global_position
		generate_horizontal_first_path(current_waypoint)
		initialize_chase()
	
	if !is_chasing:
		initialize_chase()
	
	if using_grid_movement:
		if move_sequence.size() == 0 or current_move_index >= move_sequence.size():
			generate_horizontal_first_path(current_waypoint)
		
		var path_completed = move_along_grid()
		if path_completed:
			# Check if we should advance waypoints
			var myIndex = find_closest_position_index(global_position)
			var oppIndex = find_closest_position_index(opp_pitcher.global_position)
			if myIndex == oppIndex:
				if global_position.distance_to(opp_pitcher.global_position) < chase_threshold:
					# Go directly after opponent
					current_behavior = "fighting"
					return
			advance_waypoints()
	else:
		# Old movement logic
		var myIndex = find_closest_position_index(global_position)
		var oppIndex = find_closest_position_index(opp_pitcher.global_position)
		if myIndex == oppIndex:
			# If we're closer than chase threshold, go directly after opponent
			if global_position.distance_to(opp_pitcher.global_position) < chase_threshold:
				var direction = global_position.direction_to(opp_pitcher.global_position).normalized()
				var speed = get_buffed_attribute("sprint_speed") if status.boost > 0 else get_buffed_attribute("speed")
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
						var speed = get_buffed_attribute("sprint_speed") if status.boost > 0 else get_buffed_attribute("speed")
						velocity = direction * speed
						move_and_slide()
						return
		move_around()
	
	last_reaction_check += get_process_delta_time()
	if last_reaction_check >= REACTION_CHECK_INTERVAL && direction_changes_this_pitch < MAX_DIRECTION_CHANGES:
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
	has_made_first_move = false  # Reset so we initialize waypoints properly

func reconsider_chase_direction():
	if running_positions.size() < 2:
		return
		
	# Check if we've already used all our direction changes for this pitch
	if direction_changes_this_pitch >= MAX_DIRECTION_CHANGES:
		return
	
	# Check if opponent is chasing in same direction
	if opp_pitcher.current_behavior == "chasing" && moving_clockwise == opp_pitcher.moving_clockwise:
		if direction_changes_this_pitch < MAX_DIRECTION_CHANGES:
			moving_clockwise = !moving_clockwise
			direction_changes_this_pitch += 1
			direction_changes += 1
		return
	
	# Normal direction reconsideration
	var opp_predicted_pos = opp_pitcher.global_position + opp_pitcher.velocity * 0.5
	var target_index = find_closest_position_index(opp_predicted_pos)
	var my_index = find_closest_position_index(global_position)
	var clockwise_distance = calculate_clockwise_distance(my_index, target_index)
	var counter_distance = calculate_counter_distance(my_index, target_index)
	var should_change = (moving_clockwise && counter_distance < clockwise_distance * 0.8) || \
					   (!moving_clockwise && clockwise_distance < counter_distance * 0.8)
	
	if should_change && direction_changes_this_pitch < MAX_DIRECTION_CHANGES:
		direction_changes_this_pitch += 1
		direction_changes += 1
		moving_clockwise = !moving_clockwise

func flee():
	if current_waypoint == Vector2.ZERO:
		# Find the nearest track waypoint and go there horizontally first
		var closest_index = find_closest_position_index(global_position)
		current_waypoint = running_positions[closest_index].global_position
		generate_horizontal_first_path(current_waypoint)
		initialize_flee()
	
	if !is_fleeing:
		initialize_flee()
	
	if using_grid_movement:
		if move_sequence.size() == 0 or current_move_index >= move_sequence.size():
			generate_horizontal_first_path(current_waypoint)
		
		var path_completed = move_along_grid()
		if path_completed:
			advance_waypoints()
	else:
		# Old movement logic
		var speed = calculate_flee_speed()
		move_around(speed)
		if current_waypoint != Vector2.ZERO && global_position.distance_to(current_waypoint) < 5.0:
			# Reset direction changes when reaching waypoint (but keep track of pitch limit)
			direction_changes = 0
			if randf_range(0,100) < get_buffed_attribute("reactions") and direction_changes_this_pitch < MAX_DIRECTION_CHANGES:
				reconsider_flee_direction()
			advance_waypoints()
	
	last_reaction_check += get_process_delta_time()
	if last_reaction_check >= REACTION_CHECK_INTERVAL && direction_changes_this_pitch < MAX_DIRECTION_CHANGES:
		last_reaction_check = 0.0
		if randf_range(0,100) < get_buffed_attribute("reactions"):
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
	has_made_first_move = false  # Reset so we initialize waypoints properly

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
			return get_buffed_attribute("sprint_speed")
		else:
			return get_buffed_attribute("speed")
	else:
		return get_buffed_attribute("speed") * 0.5 #walk

func reconsider_flee_direction():
	if running_positions.size() < 2:
		return
	
	# Check if we've already used all our direction changes for this pitch
	if direction_changes_this_pitch >= MAX_DIRECTION_CHANGES:
		return
	
	var my_index = find_closest_position_index(global_position)
	var opp_index = find_closest_position_index(opp_pitcher.global_position)
	
	var clockwise_distance = calculate_clockwise_distance(opp_index, my_index)
	var counter_distance = calculate_counter_distance(opp_index, my_index)
	
	var should_change = (moving_clockwise && clockwise_distance < counter_distance * 0.8) || \
					   (!moving_clockwise && counter_distance < clockwise_distance * 0.8)
	
	if should_change && direction_changes_this_pitch < MAX_DIRECTION_CHANGES:
		direction_changes_this_pitch += 1
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
		if randf() < 0.6 or direction_changes_this_pitch >= MAX_DIRECTION_CHANGES:
			return true
		else:
			reconsider_flee_direction()
	return false

func chill():
	current_behavior = "chilling"
	direction_changes = 0
	
	# If we're in chilling state, stay at rest position area
	if !current_chill_target or global_position.distance_to(current_chill_target) < chill_target_reached_threshold:
		current_chill_target = get_random_chill_target()
	
	# Move very slowly toward chill target
	var move_direction = global_position.direction_to(current_chill_target)
	velocity = move_direction * (get_buffed_attribute("speed") * 0.05)  # Much slower movement
	move_and_slide()
	
	# Reset velocity if we're moving too fast for chilling
	if velocity.length() > get_buffed_attribute("speed") * 0.1:
		velocity = velocity.normalized() * (get_buffed_attribute("speed") * 0.05)
	
	last_reaction_check += get_process_delta_time()
	if last_reaction_check >= REACTION_CHECK_INTERVAL:
		last_reaction_check = 0.0
		check_chill_state()
		
func fight_footwork():
	current_behavior = "fighting"
	if !opp_pitcher:
		return
	
	# IMPORTANT: When fighting, do NOT break away! Stay in fight.
	var direction: Vector2
	if global_position.distance_to(opp_pitcher.global_position) > 30:
		direction = global_position.direction_to(opp_pitcher.global_position)
	else:
		# If too close, move randomly within a small radius
		direction = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	
	# Very slow movement during fight
	velocity = direction * (get_buffed_attribute("speed") * 0.08)
	move_and_slide()
	
	# Keep velocity minimal - no running away during fights
	if velocity.length() > get_buffed_attribute("speed") * 0.1:
		velocity = velocity.normalized() * (get_buffed_attribute("speed") * 0.08)
	
func fight_or_flight():
	var base_flee = scrapping["flee"]
	var base_fight = scrapping["fight"]
	var base_chill = scrapping["chill"]
	var base_track = scrapping["track"]
	var attribute_modifier = 0.0
	
	var tough_diff = opp_pitcher.get_buffed_attribute("toughness") - get_buffed_attribute("toughness")
	var speed_diff = opp_pitcher.get_buffed_attribute("speed") - get_buffed_attribute("speed")
	
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
	var total = base_flee + base_fight + base_chill + base_track
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
		# Find the nearest track waypoint and go there horizontally first
		var closest_index = find_closest_position_index(global_position)
		current_waypoint = running_positions[closest_index].global_position
		generate_horizontal_first_path(current_waypoint)
		has_made_first_move = false
	else:
		move_around()
	
func move_around(input_speed: float = -1.0):
	if current_waypoint == Vector2.ZERO:
		# Find the nearest track waypoint and go there horizontally first
		var closest_index = find_closest_position_index(global_position)
		current_waypoint = running_positions[closest_index].global_position
		generate_horizontal_first_path(current_waypoint)
	
	var is_vertical_movement = false
	if running_positions.size() > current_path_index:
		var next_index = current_path_index + 1 if moving_clockwise else current_path_index - 1
		if next_index >= running_positions.size():
			next_index = 0
		elif next_index < 0:
			next_index = running_positions.size() - 1
		var current_pos = running_positions[current_path_index].global_position
		var next_pos = running_positions[next_index].global_position
		if abs(current_pos.y - next_pos.y) > abs(current_pos.x - next_pos.x):
			is_vertical_movement = true
	if is_vertical_movement and current_behavior in ["chasing", "fleeing", "tracking"]:
		var distance_factor = 1.0
		if opp_pitcher:
			var distance_to_opp = global_position.distance_to(opp_pitcher.global_position)
			var max_track_distance = 1000.0  # Adjust based on your track size
			distance_factor = clamp(distance_to_opp / max_track_distance, 0.1, 1.0)
		var discipline_check = randi_range(0, 100)
		var discipline_threshold = get_buffed_attribute("discipline") * distance_factor
		if discipline_check > discipline_threshold:
			discipline_check = randi_range(0, 100)
			if discipline_check > discipline_threshold:
				print(bio.last_name + " is cutting the corner!")
				is_cutting_corner = true
				discipline_failures = 0
				
				# Skip to team-appropriate rest position
				if team == 1:  # Human team - go to South
					current_waypoint = south_position
				else:  # CPU team - go to North
					current_waypoint = north_position
				
				generate_horizontal_first_path(current_waypoint)
				return
	if !is_vertical_movement:
		discipline_failures = 0
	
	if current_behavior == "tracking" and using_grid_movement:
		if move_sequence.size() == 0 or current_move_index >= move_sequence.size():
			generate_horizontal_first_path(current_waypoint)
		
		var path_completed = move_along_grid()
		if path_completed:
			advance_waypoints()
	else:
		# Check if we've reached the current waypoint with better precision
		var distance_to_waypoint = global_position.distance_to(current_waypoint)
		if distance_to_waypoint < 20:  # Increased tolerance for waypoint reaching
			if is_cutting_corner:
				var target_position = south_position if team == 1 else north_position
				if global_position.distance_to(target_position) < 20:
					is_cutting_corner = false
					advance_waypoints()  # Continue to next waypoint after rest position
				else:
					var speed
					if input_speed == -1:
						if status.boost > 0:
							speed = get_buffed_attribute("sprint_speed")
						else:
							speed = get_buffed_attribute("speed")
					else:
						speed = input_speed
					
					var base_direction = global_position.direction_to(current_waypoint)
					velocity = base_direction * speed
					move_and_slide()
					
					if status.boost > 0 and speed == get_buffed_attribute("sprint_speed"):
						status.boost = max(0, status.boost - 0.25)
					return
			else:
				advance_waypoints()
		
		var speed
		if input_speed == -1:
			if status.boost > 0:
				speed = get_buffed_attribute("sprint_speed")
			else:
				speed = get_buffed_attribute("speed")
		else:
			speed = input_speed
		
		# Get direction to waypoint
		var direction = global_position.direction_to(current_waypoint)
		
		# Normalize the direction to prevent diagonal movement preference
		if abs(direction.x) > abs(direction.y):
			direction = Vector2(1 if direction.x > 0 else -1, 0)
		else:
			direction = Vector2(0, 1 if direction.y > 0 else -1)
		
		velocity = direction * speed
		move_and_slide()
		
		if status.boost > 0 and speed == get_buffed_attribute("sprint_speed"):
			status.boost = max(0, status.boost - 0.25)

func initialize_waypoints():
	if !has_made_first_move:
		# For non-throwing pitcher - wait until opponent is at track
		if current_behavior == "waiting":
			# We should not initialize waypoints while waiting
			return
		
		if current_behavior == "faceoff_recover" and legal_first_moves.size() == 2 and is_faceoff_recover:
			if moving_clockwise:
				current_waypoint = running_positions[legal_first_moves[0]].global_position
				current_path_index = legal_first_moves[0]
			else:
				current_waypoint = running_positions[legal_first_moves[1]].global_position
				current_path_index = legal_first_moves[1]
		else:
			var closest_index = find_closest_position_index(global_position)
			current_path_index = closest_index
			current_waypoint = running_positions[current_path_index].global_position
		has_made_first_move = true
		generate_horizontal_first_path(current_waypoint)
	else:
		if moving_clockwise:
			current_path_index = (current_path_index + 1) % running_positions.size()
		else:
			current_path_index = (current_path_index - 1 + running_positions.size()) % running_positions.size()
		current_waypoint = running_positions[current_path_index].global_position
		generate_horizontal_first_path(current_waypoint)

func advance_waypoints():
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
	if !is_cutting_corner:
		current_waypoint = running_positions[current_path_index].global_position
		generate_horizontal_first_path(current_waypoint)

func handle_going_away():
	current_waypoint = rest_position
	var speed
	if status.boost > 0:
		speed = get_buffed_attribute("sprint_speed")
		status.boost = status.boost - 0.25
	else:
		speed = get_buffed_attribute("speed")
	
	# Move toward rest position
	var move_direction = global_position.direction_to(rest_position)
	
	# Normalize movement to prevent diagonal drift
	if abs(move_direction.x) > abs(move_direction.y):
		move_direction = Vector2(1 if move_direction.x > 0 else -1, 0)
	else:
		move_direction = Vector2(0, 1 if move_direction.y > 0 else -1)
	
	velocity = move_direction * speed
	move_and_slide()
	
	if global_position.distance_to(rest_position) <= 10:  # Increased tolerance
		# At rest position, now go to the track horizontally
		current_behavior = "going_to_track"
		going_to_track = true
		# Find the closest track corner from the rest position
		var closest_index = find_closest_position_index(rest_position)
		track_target_corner = running_positions[closest_index].global_position
		# Clear any existing path and generate horizontal-first path
		move_sequence = []
		current_move_index = 0
		generate_horizontal_first_path(track_target_corner)

func go_to_track_start():
	# For non-throwing pitcher - start moving to track
	going_to_track = true
	# Find the closest track corner from current position (not rest position!)
	var closest_index = find_closest_position_index(global_position)
	track_target_corner = running_positions[closest_index].global_position
	# Clear any existing path and generate horizontal-first path
	move_sequence = []
	current_move_index = 0
	generate_horizontal_first_path(track_target_corner)

func go_to_track():
	if !going_to_track:
		return
	
	# Move along the grid path
	var path_completed = move_along_grid()
	if path_completed and current_move_index >= move_sequence.size():
		# Successfully reached the track corner
		going_to_track = false
		current_behavior = "deciding"
		current_waypoint = Vector2.ZERO
		has_arrived = true
		velocity = Vector2.ZERO
		move_sequence = []

func find_closest_position_index(position: Vector2) -> int:
	var closest_index = 0
	var closest_distance = INF
	for i in running_positions.size():
		var dist = position.distance_to(running_positions[i].global_position)
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
	if randf() < 0.3 * get_buffed_attribute("reactions"):
		var my_index = find_closest_position_index(global_position)
		var opp_index = find_closest_position_index(opp_pitcher.global_position)
		var current_distance = min(
			calculate_clockwise_distance(opp_index, my_index),
			calculate_counter_distance(opp_index, my_index)
		)
		if current_distance < running_positions.size() * 0.1:
			if randf() < 0.8 * get_buffed_attribute("toughness"):
				flee()
				
func set_groove():
	status.groove = get_buffed_attribute("confidence")
	
func find_groove(effect: float):
	status.groove = status.groove + effect
	if status.groove > get_buffed_attribute("confidence"):
		status.groove = get_buffed_attribute("confidence")
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
	powerbar.color(current_variance)
