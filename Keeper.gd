extends Player
class_name Keeper

# Behavior Parameters
@export var avoidance_weights := {
	"forward_proximity": 1.5,
	"goal_proximity": 0.8,
	"dodge_threshold": 20.0,
	"fence_threshold": 50.0,
	"panic_threshold": 20.0,
	"chill_threshold": 30
}

@export var sweeping_params := {
	"max_distance" : 60,
	"min_distance" : 30,
	"slow": 100,
	"grumpy_frames": 3000
}

@export var attack_params := {
	"attack_range": 100.0,
	"target_switch_threshold": 50.0,
	"cooldown_time": 0.8
}

@export var guess_preferences := {
	"left": 0.4,
	"middle": 0.2,
	"right": 0.4,
	"memory": 0.3
}
var has_guessed: bool = false

# State
var own_goal: Vector2
var opp_goal: Vector2
var leftPost: Vector2
var rightPost: Vector2
var left_wall: StaticBody2D
var right_wall: StaticBody2D
var back_wall: StaticBody2D
var ball_last_position: Vector2
var ball_last_velocity: Vector2
var time_since_last_touch: float = 0.0
var buddyLF
var buddyRF
var buddyLG
var buddyRG
var oppLF
var oppRF
var oppKeeper
var desperate: bool = false #activated depending on game state. Impacts decision making

# defending the ball
const max_goal_offset: float = 29.5
var reaction_timer: float = 0
var reacting: bool = false
var last_ball_direction: Vector2 = Vector2.ZERO
var current_position: Vector2 = Vector2.ZERO
var ball_last_sighted: Vector2 = Vector2.ZERO
var ball_direction_projection: Vector2 = Vector2.ZERO
var pitches_left: int = 0 #counts number of pitches that went left
var pitches_middle: int = 0
var pitches_right: int = 0
var last_guess: String
var hold_frame: int = 15
var is_human_blocking: bool = false
var human_block_timer: float = 0.0
var human_block_target: Vector2
var human_block_speed_multiplier: float = 1.2
const HUMAN_BLOCK_DURATION: float = 0.2  # How long to override input
# Constants
const MAX_REACTION_TIME: float = 0.5  # seconds
const MIN_REACTION_TIME: float = 0.1  # seconds
const BASE_AGGRESSION_DISTANCE: float = 100.0  # pixels
const POSITIONING_VARIANCE: float = 30.0  # max variance in pixels
const ANTICIPATION_DISTANCE: float = 200.0  # how far ahead to look for ball path
const BLOCKING_BONUS: float = 1.5 #bonus speed when blocking
const HUMAN_EFFECT: float = 4 #more bonus for blocking to overcome natural desire not to move

# Navigation
var navigation_agent: NavigationAgent2D
var ignore_x_input: bool = false

func _ready():
	debug = false
	z_index = 2
	desperate = false #TODO: figure out when to set desperate
	restore_behaviors()
	current_behavior = "waiting"
	super._ready()
	position_type = "keeper"
	navigation_agent = $NavigationAgent2D
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 10.0

func restore_behaviors():
	behaviors = ["waiting", "defending", "sweeping", "avoiding", "fencing", "attacking", "blocking", "returning", "pitch_defense"]

func _physics_process(delta):
	super._physics_process(delta)
	if !can_move:
		velocity = Vector2.ZERO
		return
	if is_human_blocking:
		if is_machine:
			if handle_super_blocking(delta):
				move_and_slide()
				return
		elif handle_human_blocking(delta):
			move_and_slide()
			return  # Skip normal input processing while blocking
	if is_special_active():
		use_special_ability()
	
	
	if not is_controlling_player and can_move:
		print("current behavior: ", current_behavior)
		AI_behavior(delta)
		#if !is_in_half():
			#if !is_stunned:
				#move_towards_half()
		#print(current_behavior, " location: ", global_position, " | target: ", navigation_agent.target_position)
		if debug:
			current_debug_frame += 1
			if current_debug_frame >= debug_frames:
				current_debug_frame = 0
				print(current_behavior)
	elif GlobalSettings.semiAuto and is_controlling_player and can_move:
		print("semi automatic control: " + current_behavior)
		if current_behavior == "waiting" and oppKeeper.current_behavior != "waiting":
			current_behavior = "defending"
		AI_behavior(delta)
		human_aim()
		
		move_and_slide()
	else:
		human_aim()
		if Input.is_action_just_pressed("activate_special_ability"):
			if status.groove > 0:
				activate_special_ability()
		human_check_ball_close()
		move_and_slide()
		
func human_aim():
	if aim_target:
			aim_target.on = true
			aim = aim_target.global_position

#region Behavior Implementations
func AI_behavior(delta):
	time_since_last_touch += delta
	# Update ball tracking
	if ball:
		ball_last_velocity = (ball.global_position - ball_last_position) / delta
		ball_last_position = ball.global_position
	
	match current_behavior:
		"waiting":
			perform_waiting()
		"holding":
			perform_holding(hold_frame)
		"defending":
			defending_behavior(delta)
			check_state()
		"blocking":
			perform_blocking()
		"sweeping":
			perform_sweeping()
		"avoiding":
			perform_avoiding()
		"fencing":
			perform_fencing()
		"attacking":
			perform_attacking()
		"guessing":
			perform_guessing()
		"pitch_defense":
			perform_pitch_defense()
			
			
func perform_waiting():
	navigation_agent.target_position = global_position
	velocity = Vector2.ZERO
	
	# Tiny idle movements
	if randf() < 0.01:
		var tiny_wander = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		navigation_agent.target_position = tiny_wander
	
	## Transition if ball comes close
	#if ball and global_position.distance_to(ball.global_position) < 600:
		#current_behavior = "defending"
		

#decide what state to be in
func check_state():
	if !ball:
		return
	if current_behavior == "waiting": #sit down and wait!
		return
	
	var ball_speed = ball_last_velocity.length()
	var ball_to_goal = (own_goal - ball.global_position).normalized()
	var ball_direction = ball_last_velocity.normalized()
	var goal_threat = ball_direction.dot(ball_to_goal)
	
	var ball_dist_to_goal = ball.global_position.distance_squared_to(own_goal)
	var keeper_dist_to_goal = global_position.distance_squared_to(own_goal)
	var keeper_dist_to_ball = global_position.distance_to(ball.global_position)
	
	# Check for avoiding conditions (forward pressure)
	var closest_opponent = get_closest_opponent()
	if closest_opponent and global_position.distance_to(closest_opponent.global_position) < avoidance_weights["panic_threshold"]:
		current_behavior = "avoiding"
		return
	#check to see if we ought to sweep
	elif global_position.distance_to(ball.global_position) < 150 - attributes.aggression: #100 to 51
		_make_sweeping_decision()
	else:
		current_behavior = "defending"

func perform_sweeping():
	if !ball:
		current_behavior = "defending"
		return
	
	var goal_line_y = leftPost.y
	var buffer = 10.0  # Stay at least this far in front of goal line
	
	var distance_to_ball = global_position.distance_to(ball.global_position)
	
	# Check if we've reached the ball or gotten close enough
	if distance_to_ball < 2 or (time_since_last_touch < 0.1):
		# Successfully collected the ball - sprint back to defensive position
		var goal_center = (leftPost + rightPost) / 2
		var defensive_y = goal_line_y - sign(goal_line_y) * buffer
		var defensive_position = Vector2(goal_center.x, defensive_y)
		navigation_agent.target_position = defensive_position
		# Sprint back at full speed but don't go beyond goal line
		var move_dir = (defensive_position - global_position).normalized()
		velocity = move_dir * attributes.sprint_speed
		# Once we're back in position, switch to defending
		if global_position.distance_to(defensive_position) < 20:
			current_behavior = "defending"
			return
	if check_ball_close():
		return
	
	var anticipated_pos = _calculate_ball_intercept_with_bounces()
	
	if sign(goal_line_y) > 0:  # Bottom goal (positive Y)
		anticipated_pos.y = min(anticipated_pos.y, goal_line_y - buffer)
	else:  # Top goal (negative Y)
		anticipated_pos.y = max(anticipated_pos.y, goal_line_y + buffer)
	if sign(global_position.y) != sign(anticipated_pos.y) or anticipated_pos.distance_squared_to(Vector2(0,0)) > own_goal.distance_squared_to(Vector2(0,0)):
		current_behavior = "defending"
		return
	if global_position.distance_squared_to(anticipated_pos) > ball.global_position.distance_squared_to(own_goal):
		current_behavior = "defending"
		return
	var ball_to_center = (Vector2(0, 0) - ball.global_position).normalized()
	if (global_position - anticipated_pos).normalized().dot(ball_to_center) < 0.7:
		#get the fuck back in the goal
		is_sprinting = status.boost > 0
		var speed = attributes.speed
		if is_sprinting:
			speed = attributes.sprint_speed
		navigation_agent.target_position = own_goal
		velocity = (navigation_agent.target_position - global_position).normalized() * speed
		return
	
	navigation_agent.target_position = anticipated_pos
	velocity = (anticipated_pos - global_position).normalized() * attributes.sprint_speed
	if distance_to_ball > sweeping_params["max_distance"]:
		current_behavior = "defending"
	
func _calculate_ball_intercept_with_bounces() -> Vector2:
	if !ball or ball_last_velocity.length() < 50:
		return ball.global_position
	
	var current_pos = ball.global_position
	var current_vel = ball_last_velocity
	var keeper_speed = attributes.sprint_speed
	var max_bounces = 2
	var bounce_count = 0
	var goal_line_y = leftPost.y
	var buffer = 15.0  # Stay in front of goal
	
	# Try to find where we can intercept the ball
	while bounce_count <= max_bounces:
		# Calculate time for keeper to reach current ball position
		var distance_to_intercept = global_position.distance_to(current_pos)
		var keeper_time = distance_to_intercept / keeper_speed
		
		# Project where ball will be when keeper arrives
		var ball_future_pos = current_pos + current_vel * keeper_time
		
		# Check for wall collision before keeper arrives
		var wall_collision = _check_wall_collision(current_pos, current_vel, keeper_time)
		
		if wall_collision.has("collision"):
			# Ball will bounce - update position and velocity for next iteration
			current_pos = wall_collision["position"]
			current_vel = wall_collision["new_velocity"]
			bounce_count += 1
		else:
			# No wall collision - this is our intercept point
			# Ensure we don't go behind goal line
			if sign(goal_line_y) > 0:  # Bottom goal
				ball_future_pos.y = min(ball_future_pos.y, goal_line_y - buffer)
			else:  # Top goal
				ball_future_pos.y = max(ball_future_pos.y, goal_line_y + buffer)
			return ball_future_pos
	
	# If we can't predict after max bounces, just go for current ball position
	# Still respect goal boundary
	if sign(goal_line_y) > 0:
		current_pos.y = min(current_pos.y, goal_line_y - buffer)
	else:
		current_pos.y = max(current_pos.y, goal_line_y + buffer)
	return current_pos

func perform_avoiding():
	var closest_opponent = get_closest_opponent()
	if !closest_opponent or global_position.distance_squared_to(closest_opponent.global_position) >= avoidance_weights.chill_threshold :
		current_behavior = "defending"
		return
	
	var threat = _calculate_forward_threat(closest_opponent)
	if threat > 0.9 and randf() < attributes.aggression / 99.0:
		if status.anger + attributes.aggression >= 120: #120 instead of 100 because the keeper needs to focus on the goal
			current_behavior = "fencing"
			current_opponent = closest_opponent
			return
	
	var avoidance_pos = _calculate_avoidance_position(threat, 0.0)
	navigation_agent.target_position = avoidance_pos
	velocity = (avoidance_pos - global_position).normalized() * attributes.speed
	
	if threat > 0.5 and randf() < 0.05:
		super.attempt_dodge()

func perform_fencing():
	if !current_opponent or current_opponent.is_stunned:
		current_behavior = "defending"
		current_opponent = null
		return
	
	if _should_break_fencing():
		current_behavior = "defending"
		current_opponent = null
		return
	if global_position.distance_squared_to(current_opponent.global_position) < 400: #dist less than 20, saving some compute
		if current_opponent.current_behavior != "brawling":
			current_opponent.jumped_brawl(self)
		brawl_footwork(current_opponent)
	else:
		navigation_agent.target_position = current_opponent.global_position
		velocity = global_position.direction_to(navigation_agent.target_position).normalized() * attributes.speed

func perform_attacking():
	if attack_cooldown > 0:
		attack_cooldown -= get_physics_process_delta_time()
		velocity *= 0.9
		return
	
	if !attack_target or attack_target.is_stunned:
		attack_target = _select_attack_target()
		if !attack_target:
			current_behavior = "defending"
			return
	
	velocity = (attack_target.global_position - global_position).normalized() * attributes.sprint_speed
	
	if global_position.distance_to(attack_target.global_position) < attack_params["attack_range"]:
		_execute_attack(attack_target.global_position)
#endregion

func _make_sweeping_decision():
	if !goalkeeping_preferences.sweeper_keeper:
		print("homie don't play like that")
		current_behavior = "defending"
		return
	var ball_speed = ball_last_velocity.length()
	var opponent_dist = global_position.distance_to(get_closest_opponent().global_position)
	var goal_dist = global_position.distance_to(own_goal)
	var dist_modifier #go for it if it's safe
	if goal_dist < opponent_dist:
		dist_modifier = 1.25
	else:
		dist_modifier = 0.75
	var corner_modifier #go for it if it's in the corner
	if abs(ball.global_position.y) - own_goal.y < 10:
		corner_modifier = 2
	else:
		corner_modifier = 1
	var keeper_bias = (attributes.aggression * 0.7 + attributes.confidence * 0.3) / 100.0#have o want it and believe in yourself
	var clearness = _path_clearness(global_position, ball.global_position)
	var choice = clearness * keeper_bias * dist_modifier * corner_modifier
	if ball.last_touched_time > 180:
		choice = choice * 1.2
	elif ball.last_touched_time > 90:
		choice = choice * 1.1
	if randf() < choice:
		current_behavior = "sweeping"
		print("gimme that ball!")
	else:
		current_behavior = "defending"
	if (ball.global_position.y < 0 and own_goal.y > 0) or (ball.global_position.y > 0 and own_goal.y < 0):
		current_behavior = "defending"


func _determine_strike_target() -> Vector2:
	if _can_shoot_directly():
		return opp_goal
	
	var strategy_choice = weighted_random_choice(
		["shoot", "pass", "miss"],
		[team_strategy.shoot, team_strategy.pass, team_strategy.miss]
	)
	
	match strategy_choice:
		"shoot":
			return _calculate_bank_shot_target()
		"pass":
			var pass_target = _find_pass_target()
			return pass_target if pass_target else _calculate_miss_target()
		"miss":
			return _calculate_miss_target()
	
	return opp_goal

func _execute_strike(strike_vector: Vector2):
	if global_position.distance_to(ball.global_position) < 50:
		ball.apply_force(strike_vector)
		time_since_last_touch = 0.0

func _execute_attack(target: Vector2):
	super.attempt_attack(target)
	attack_cooldown = attack_params["cooldown_time"]
	
	if attack_target.is_stunned:
		attack_target = _find_secondary_target()
		if !attack_target:
			current_behavior = "defending"
#endregion

#region Utility Functions
func _is_ball_near_wall() -> bool:
	return (ball.global_position.distance_to(left_wall.global_position) < 100 or
			ball.global_position.distance_to(right_wall.global_position) < 100 or
			ball.global_position.distance_to(back_wall.global_position) < 100)

func _calculate_forward_threat(forward: Player) -> float:
	if !forward:
		return 0.0
	
	var dist = global_position.distance_to(forward.global_position)
	var dist_threat = 1.0 - clamp(dist / avoidance_weights["panic_threshold"], 0.0, 1.0)
	
	var velocity_component = 0.0
	if forward.velocity.length() > 100:
		var angle = forward.velocity.normalized().angle_to((global_position - forward.global_position).normalized())
		velocity_component = (1.0 - abs(angle)/PI) * 0.5
	
	return clamp(dist_threat + velocity_component, 0.0, 1.0)

func get_closest_opponent() -> Player:
	var L= global_position.distance_squared_to(oppLF.global_position)
	var R= global_position.distance_squared_to(oppRF.global_position)
	if L < R:
		return oppLF
	else:
		return oppRF

func _calculate_avoidance_position(threat_left: float, threat_right: float) -> Vector2:
	var goal_center = (leftPost + rightPost) / 2
	var repulsion = Vector2.ZERO
	
	if oppLF and threat_left > 0:
		repulsion += (global_position - oppLF.global_position).normalized() * threat_left * avoidance_weights["forward_proximity"]
	
	if oppRF and threat_right > 0:
		repulsion += (global_position - oppRF.global_position).normalized() * threat_right * avoidance_weights["forward_proximity"]
	
	var target_pos = global_position + (repulsion + (goal_center - global_position).normalized() * avoidance_weights["goal_proximity"]) * 200.0
	return goal_center + (target_pos - goal_center).limit_length(leftPost.distance_to(goal_center) * 1.5)

func _should_break_fencing() -> bool:
	return ball and global_position.distance_to(ball.global_position) < fencing_params["ball_proximity_threshold"] * (1.1 - attributes.reactions/100.0)

func _select_attack_target() -> Player:
	var valid_targets = []
	if oppLF and !oppLF.is_stunned:
		valid_targets.append(oppLF)
	if oppRF and !oppRF.is_stunned:
		valid_targets.append(oppRF)
	
	if valid_targets.is_empty():
		return null
	
	valid_targets.sort_custom(func(a, b): 
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	return valid_targets[0]

func _find_secondary_target() -> Player:
	var potential_targets = []
	if oppLF and !oppLF.is_stunned and global_position.distance_to(oppLF.global_position) < attack_params["target_switch_threshold"]:
		potential_targets.append(oppLF)
	if oppRF and !oppRF.is_stunned and global_position.distance_to(oppRF.global_position) < attack_params["target_switch_threshold"]:
		potential_targets.append(oppRF)
	
	if potential_targets.is_empty():
		return null
	
	potential_targets.sort_custom(func(a, b):
		return a.global_position.distance_to(own_goal) < b.global_position.distance_to(own_goal))
	return potential_targets[0]

func _can_shoot_directly() -> bool:
	if _path_clearness(global_position, opp_goal) > (0.7 - (0.3 * attributes.aggression/99.0)) or oppKeeper.global_position.distance_to(opp_goal) > 250:
		return true
	else:
		return false

func _calculate_bank_shot_target() -> Vector2:
	var use_left = randf() > 0.5
	var wall_pos = left_wall.global_position if use_left else right_wall.global_position
	var wall_normal = Vector2(1, 0) if use_left else Vector2(-1, 0)
	
	if randf() < 0.6:  # One-bank
		return (Vector2(opp_goal.x + (100 if use_left else -100), opp_goal.y - 150) - wall_pos).bounce(wall_normal) * 1.5
	else:  # Two-bank
		return (Vector2(right_wall.global_position.x if use_left else left_wall.global_position.x, back_wall.global_position.y) - wall_pos).bounce(wall_normal) * 1.8

func _find_pass_target() -> Variant:
	var options = []
	var weights = []
	if buddyLF:
		var left_clear = _path_clearness(ball.global_position, buddyLF.global_position)
		if left_clear > (0.5 - (0.2 * attributes.aggression/99.0)):
			options.append(buddyLF.global_position)
			weights.append(left_clear)
	if buddyRF:
		var right_clear = _path_clearness(ball.global_position, buddyRF.global_position)
		if right_clear > (0.5 - (0.2 * attributes.aggression/99.0)):
			options.append(buddyRF.global_position)
			weights.append(right_clear)
	if buddyLG:
		var left_clear = _path_clearness(ball.global_position, buddyLG.global_position)
		if left_clear > (0.5 - (0.2 * attributes.aggression/99.0)):
			if buddyLG.is_countering():
				left_clear *= 1.5 #make the easy pass
			options.append(buddyLF.global_position)
			weights.append(left_clear)
	if buddyRG:
		var right_clear = _path_clearness(ball.global_position, buddyRG.global_position)
		if right_clear > (0.5 - (0.2 * attributes.aggression/99.0)):
			if buddyLG.is_countering():
				right_clear *= 1.5 #make the easy pass
			options.append(buddyLF.global_position)
			weights.append(right_clear)
	return options[weighted_random_choice(range(options.size()), weights)] if !options.is_empty() else null

func _calculate_miss_target() -> Vector2:
	var use_left = randf() > 0.5
	return Vector2(
		left_wall.global_position.x + 100 if use_left else right_wall.global_position.x - 100,
		back_wall.global_position.y * 0.8
	)

func _calculate_strike_parameters(target_pos: Vector2) -> Variant:
	var ball_future = ball.global_position + ball_last_velocity * 1.0
	var strike_dir = (target_pos - ball_future).normalized()
	var intercept = ball_future - (strike_dir * 30.0)
	
	if intercept.distance_to(global_position) > 500:
		return null
	
	return [intercept, strike_dir * (800 + 200 * attributes.aggression/99.0)]

#returns a float between 0 to 1 representing how open the ball's path is
func _path_clearness(from_pos: Vector2, to_pos: Vector2) -> float:
	var space = 1.0
	var dir = (to_pos - from_pos).normalized()
	var dist = from_pos.distance_to(to_pos)
	
	for i in range(1, int(dist / 50)):
		var check_pos = from_pos + dir * i * 50
		for opponent in [oppKeeper, oppLF, oppRF]:
			if opponent.global_position.distance_to(check_pos) < 60:
				space -= 0.4
				break
	
	return clamp(space, 0.0, 1.0)

func weighted_random_choice(options: Array, weights: Array):
	var total = weights.reduce(func(a, b): return a + b, 0.0)
	var roll = randf() * total
	var cumulative = 0.0
	
	for i in options.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return options[i]
	
	return options[0]
#endregion

#called when the ball is shot by an opposing forward
func on_shot_at_goal(shot_from: Vector2, shot_direction: Vector2 , shooter_team: int):
	var intercept
	if shooter_team == team: #not my problem
		return 
	if abs(shot_direction.y) < 0.001 or abs(1 - shot_direction.y) < 0.001: #vertical shot- protect from dividing by 0
		print("vertical shot")
		intercept = Vector2(shot_from.y, global_position.x)
	else: #normal intercept
		intercept = shot_from + shot_direction * ((leftPost.y - shot_from.y) / shot_direction.y)
	var reaction_time = map_attribute_to_reaction_time(attributes.reactions)
	await get_tree().create_timer(reaction_time).timeout
	var goal_width = leftPost.distance_to(rightPost)
	if !is_controlling_player and !is_stunned:
		ball_last_sighted = shot_from
		ball_direction_projection = shot_direction
		current_behavior = "blocking"
	elif !is_stunned and !is_dodging and velocity == Vector2(0,0) and abs(intercept.x - own_goal.x) < goal_width * 0.6:#slight buffer but has to be basically on goal
		if is_machine:
			super_block(shot_from, intercept)
		else:
			human_assisted_block(shot_from, intercept)

func human_assisted_block(shot_from: Vector2, intercept: Vector2):
	print("human assisted block initiated")
	# Calculate the intercept point
	var diff = global_position.x - intercept.x
	var block_distance = (25*(attributes.blocking - 50))/49 + 5 #maximum distance we'll block
	if block_distance <= global_position.distance_to(intercept):
		if diff <= 0:
			human_block_target = Vector2(intercept.x + block_distance, global_position.y)
		else:
			human_block_target = Vector2(intercept.x, global_position.y)
		if goalkeeping_preferences.dives_backwards:
				var avg = (global_position + intercept)/2
				human_block_target = Vector2(human_block_target.x, avg.y)
	else:
		human_block_target = global_position.direction_to(intercept).normalized() * block_distance + global_position
	is_human_blocking = true #override human input
	human_block_timer = HUMAN_BLOCK_DURATION
	navigation_agent.target_position = human_block_target
	var block_direction = global_position.direction_to(human_block_target).normalized()
	velocity = block_direction * attributes.sprint_speed * human_block_speed_multiplier
	if velocity.x < 0 and ball.global_position.x > global_position.x: #we overshot!
		velocity.x = 0
	elif velocity.x > 0 and ball.global_position.x < global_position.x: #we overshot!
		velocity.x = 0

#improved block ability for if the keeper has the "shot swatter" special active
func super_block(shot_from: Vector2, intercept: Vector2):
	var ball_path = ball_last_velocity.normalized()
	var keeper_to_ball = ball.global_position - global_position
	var t = keeper_to_ball.dot(ball_path) / ball_path.dot(ball_path)
	var closest_point = ball.global_position + ball_path * t
	
	var intercept_point = closest_point
	if intercept_point.y > global_position.y:
		intercept_point.y = global_position.y - 50
	if is_controlling_player:
		is_human_blocking = true
		human_block_timer = HUMAN_BLOCK_DURATION
	human_block_target = intercept_point
	navigation_agent.target_position = human_block_target
	velocity = global_position.direction_to(intercept_point).normalized() * attributes.sprint_speed * 2 #FAST AS FUCK BOI
	
func handle_super_blocking(delta: float):
	if not is_human_blocking or status.groove <= 0 or !is_machine:
		return false
	human_block_timer -= delta
	if human_block_timer <= 0:
		is_human_blocking = false
		return false
	human_block_target = ball.global_position + ball_last_velocity * 0.1
	var block_direction = global_position.direction_to(human_block_target).normalized()
	velocity = block_direction * attributes.sprint_speed * 2.0
	return true
	
func handle_human_blocking(delta: float):
	if not is_human_blocking:
		return false
		
	human_block_timer -= delta
	if human_block_timer <= 0 or global_position.distance_to(human_block_target) < 10.0:
		is_human_blocking = false
		return false
	var block_direction
	if ball.global_position.distance_squared_to(global_position) > 100: #10 units
		block_direction = global_position.direction_to(human_block_target).normalized()
	else:
		block_direction = global_position.direction_to(ball.global_position).normalized()
	velocity = block_direction * attributes.sprint_speed * human_block_speed_multiplier
	return true # Return true to indicate we're still overriding input
			
func perform_blocking():
	#print("Not in my house")
	var goal_line = leftPost.y
	var time_to_goal = (goal_line - ball_last_sighted.y) / ball_direction_projection.y
	var intercept = ball_last_sighted + (ball_direction_projection * time_to_goal)
	var positioning_variance = (100 - attributes.positioning)/3 #16.67 at 50, 0.33 at 99
	if intercept.distance_squared_to(own_goal) > ball.global_position.distance_squared_to(own_goal) + positioning_variance:
		current_behavior = "defending"
		return
	
	if intercept.distance_to(own_goal) > max_goal_offset or is_nan(time_to_goal) or is_inf(time_to_goal) or is_nan(intercept.x) or is_nan(intercept.y) or is_inf(intercept.x) or is_inf(intercept.y):
		current_behavior = "defending"
		return
		
	var block_distance = (15*(attributes.blocking - 50))/49 + 5 #if 50, bd is 5; if 99, bd is 20
	var block_direction 
	
	if block_distance <= global_position.distance_to(intercept):
		var diff = global_position.x - intercept.x
		var target_y = intercept.y
		
		if sign(goal_line) > 0:  # Bottom goal
			target_y = min(target_y, goal_line - 1)
		else:  # Top goal
			target_y = max(target_y, goal_line + 1)
		
		if diff <= 0:
			navigation_agent.target_position = Vector2(intercept.x + block_distance, target_y)
		else:
			navigation_agent.target_position = Vector2(intercept.x - block_distance, target_y)
	else:
		var target_y = intercept.y
		if sign(goal_line) > 0:  # Bottom goal
			target_y = min(target_y, goal_line - 1)
		else:  # Top goal
			target_y = max(target_y, goal_line + 1)
		navigation_agent.target_position = Vector2(intercept.x, target_y)
	
	if ball.global_position.distance_squared_to(global_position) > 100: #10 units
		block_direction = global_position.direction_to(navigation_agent.target_position).normalized()
	else:
		block_direction = global_position.direction_to(ball.global_position).normalized()
	velocity = block_direction * attributes.sprint_speed * BLOCKING_BONUS

func ensure_in_front_of_goal_line(position: Vector2) -> Vector2:
	var goal_line_y = leftPost.y
	var corrected_position = position
	
	if sign(goal_line_y) > 0:  # Bottom goal (positive Y)
		# Goal line is at positive Y, keeper should be at smaller Y (closer to center)
		corrected_position.y = min(position.y, goal_line_y - 1)
	else:  # Top goal (negative Y)
		# Goal line is at negative Y, keeper should be at larger Y (closer to center)
		corrected_position.y = max(position.y, goal_line_y + 1)
	
	return corrected_position

func defending_behavior(delta: float):
	if !ball:
		return
	var goal_center: Vector2 = (leftPost + rightPost) / 2
	var goal_width: float = rightPost.distance_to(leftPost)
	if global_position.distance_squared_to(goal_center) > 2025: #45 units away
		navigation_agent.target_position = goal_center
		var speed = attributes.speed
		if status.boost > 0:
			is_sprinting = true
			speed = attributes.sprint_speed
		velocity = global_position.direction_to(goal_center).normalized() * speed
		return
		
	
	# Check if ball changed direction significantly - freeze reaction
	var current_ball_direction = ball_last_velocity.normalized()
	if last_ball_direction != Vector2.ZERO:
		var direction_change = last_ball_direction.angle_to(current_ball_direction)
		if abs(direction_change) > deg_to_rad(45):  # Significant direction change
			if !reacting:
				reacting = true
				reaction_timer = map_attribute_to_reaction_time(attributes.reactions)
			
			if reaction_timer > 0:
				reaction_timer -= delta
				velocity = Vector2.ZERO  # Freeze in place
				return
			else:
				reacting = false
	
	last_ball_direction = current_ball_direction
	
	# Project ball path with wall reflections
	var projected_intercept = _project_ball_path_with_reflections()
	
	if ball.global_position.y < leftPost.y + 10 and abs(ball.global_position.x) > 35: 
		# Ball in corner - position near closest post
		var pos_check = (100 - attributes.positioning) / 10
		var positioning_variance = randf_range(-pos_check, pos_check)
		var aggression_variance = attributes.aggression / 20
		
		if leftPost.distance_squared_to(ball.global_position) < rightPost.distance_squared_to(ball.global_position):
			var target_y = leftPost.y - sign(leftPost.y) * 5  # 5 units in front of goal line
			navigation_agent.target_position = Vector2(leftPost.x + aggression_variance, target_y + positioning_variance)
		else:
			var target_y = rightPost.y - sign(rightPost.y) * 5  # 5 units in front of goal line
			navigation_agent.target_position = Vector2(rightPost.x - aggression_variance, target_y + positioning_variance)
			
	elif ball.global_position.distance_to(goal_center) < (attributes.reactions / 2) + 10: #35 at 50, 59.5 at 99
		# Very close ball - go directly for it
		navigation_agent.target_position = ball.global_position
		velocity = (navigation_agent.target_position - global_position).normalized() * attributes.sprint_speed
		return
		
	else:
		# Use projected intercept for positioning
		if projected_intercept != Vector2.ZERO:
			# Position based on where ball is likely to end up
			var intercept_x = projected_intercept.x
			var ball_field_distance#TODO: different field types
			if fieldType == "road":
				ball_field_distance = ball.global_position.x / 57.0
			else:
				ball_field_distance = ball.global_position.x / 100.0
			
			var relative_x = ball_field_distance * goal_width
			# Apply positioning skill variance
			var variance_x = (100 - attributes.positioning) / 10
			variance_x = randf_range(-variance_x, variance_x)
			intercept_x += variance_x
			
			var ball_distance_to_goal_y = abs(ball.global_position.y - leftPost.y)
			intercept_x = clamp(intercept_x, goal_center.x - max_goal_offset, goal_center.x + max_goal_offset)
			var goal_line_y = leftPost.y
			var challenge_distance = min(ball_distance_to_goal_y * 0.3, goalkeeping_preferences.challenge_depth)
			var target_y = goal_line_y - sign(goal_line_y) * challenge_distance  # In front of goal line
			
			navigation_agent.target_position = Vector2(relative_x + variance_x, target_y)
		else:
			# Fallback to ball field position method
			var ball_field_distance
			if fieldType == "road":
				ball_field_distance = ball.global_position.x / 57.0
			else:
				ball_field_distance = ball.global_position.x / 100.0
			
			var relative_x = ball_field_distance * goal_width
			var variance_x = (100 - attributes.positioning) / 10
			variance_x = randf_range(-variance_x, variance_x)
			
			var goal_line_y = leftPost.y
			var target_y = goal_line_y - sign(goal_line_y) * goalkeeping_preferences.challenge_depth
			navigation_agent.target_position = Vector2(relative_x + variance_x, target_y)
	
	# Ensure we don't go too far from goal center
	var distance_from_center = abs(navigation_agent.target_position.x - goal_center.x)
	if distance_from_center > max_goal_offset:
		navigation_agent.target_position.x = goal_center.x + sign(navigation_agent.target_position.x - goal_center.x) * max_goal_offset
	var goal_line_y = leftPost.y
	if sign(goal_line_y) > 0:  # Bottom goal
		navigation_agent.target_position.y = min(navigation_agent.target_position.y, goal_line_y - 1)
	else:  # Top goal
		navigation_agent.target_position.y = max(navigation_agent.target_position.y, goal_line_y + 1)
	
	if global_position.distance_to(navigation_agent.target_position) > 40 and status.boost > 0:
		is_sprinting = true
		velocity = (navigation_agent.target_position - global_position).normalized() * attributes.sprint_speed
	else:
		velocity = (navigation_agent.target_position - global_position).normalized() * attributes.speed
	check_ball_close()

# Helper function to project ball path with wall reflections
func _project_ball_path_with_reflections() -> Vector2:
	if !ball or ball_last_velocity.length() < 50:  # Ball too slow to project
		return Vector2.ZERO
	
	var current_pos = ball.global_position
	var current_vel = ball_last_velocity
	var goal_line_y = leftPost.y
	var max_bounces = 3
	var bounce_count = 0
	
	# Check for opponent deflection potential
	var deflection_risk = _calculate_deflection_risk(current_pos, current_vel)
	if deflection_risk > 0.7:
		# High chance of deflection - use more conservative positioning
		return Vector2(current_pos.x * 0.7, goal_line_y)
	
	while bounce_count < max_bounces:
		# Calculate time to reach goal line
		if abs(current_vel.y) < 0.1:  # Ball not moving toward/away from goal
			break
			
		var time_to_goal = (goal_line_y - current_pos.y) / current_vel.y
		if time_to_goal < 0:  # Ball moving away from goal
			break
			
		var projected_x = current_pos.x + current_vel.x * time_to_goal
		
		# Check for wall collisions before reaching goal
		var wall_collision = _check_wall_collision(current_pos, current_vel, time_to_goal)
		if wall_collision.has("collision"):
			# Bounce off wall
			current_pos = wall_collision["position"]
			current_vel = wall_collision["new_velocity"]
			bounce_count += 1
			continue
		else:
			# No wall collision - ball reaches goal line
			return Vector2(projected_x, goal_line_y)
	
	return Vector2.ZERO  # Too many bounces or ball won't reach goal

# Check for wall collisions during ball projection
func _check_wall_collision(pos: Vector2, vel: Vector2, max_time: float) -> Dictionary:
	var result = {}
	var collision_time = max_time
	var collision_wall = ""
	
	# Check left wall
	if vel.x < 0 and left_wall:
		var time_to_left = (left_wall.global_position.x - pos.x) / vel.x
		if time_to_left > 0 and time_to_left < collision_time:
			collision_time = time_to_left
			collision_wall = "left"
	
	# Check right wall
	if vel.x > 0 and right_wall:
		var time_to_right = (right_wall.global_position.x - pos.x) / vel.x
		if time_to_right > 0 and time_to_right < collision_time:
			collision_time = time_to_right
			collision_wall = "right"
	
	# Check back wall
	if vel.y < 0 and back_wall:
		var time_to_back = (back_wall.global_position.y - pos.y) / vel.y
		if time_to_back > 0 and time_to_back < collision_time:
			collision_time = time_to_back
			collision_wall = "back"
	
	if collision_wall != "":
		var collision_pos = pos + vel * collision_time
		var new_vel = vel
		match collision_wall:
			"left", "right":
				new_vel.x = -new_vel.x * 0.8  # Some energy loss
			"back":
				new_vel.y = -new_vel.y * 0.8
		
		result["collision"] = true
		result["position"] = collision_pos
		result["new_velocity"] = new_vel
	
	return result

# Calculate risk of opponent deflecting the ball
func _calculate_deflection_risk(ball_pos: Vector2, ball_vel: Vector2) -> float:
	var risk = 0.0
	var ball_path_length = ball_vel.length()
	if ball_path_length < 50:
		return 0.0
	var ball_direction = ball_vel.normalized()
	# Check each opponent's proximity to ball path
	for opponent in [oppLF, oppRF]:
		if !opponent:
			continue
			
		var to_opponent = opponent.global_position - ball_pos
		var projection_length = to_opponent.dot(ball_direction)
		
		if projection_length > 0 and projection_length < ball_path_length:
			var closest_point = ball_pos + ball_direction * projection_length
			var distance_to_path = opponent.global_position.distance_to(closest_point)
			
			if distance_to_path < 100:  # Within deflection range
				var proximity_factor = 1.0 - (distance_to_path / 100.0)
				risk += proximity_factor * 0.5
	
	return clamp(risk, 0.0, 1.0)



# Helper functions
func map_attribute_to_reaction_time(reaction_rating: float) -> float:
	# Higher rating = faster reaction (shorter delay)
	var normalized = 1.0 - (reaction_rating / 99.0)
	return lerp(MIN_REACTION_TIME, MAX_REACTION_TIME, normalized)

func is_ball_moving_toward_goal() -> bool:
	var ball_vel: Vector2 = ball.linear_velocity
	if ball_vel.length_squared() < 1.0:
		return false
	
	var goal_center: Vector2 = (leftPost + rightPost) / 2
	var to_goal: Vector2 = goal_center - ball.global_position
	
	# Check if ball is moving generally toward goal (within 90° cone)
	return to_goal.normalized().dot(ball_vel.normalized()) > 0.0

func inverse_lerp(a: float, b: float, value: float) -> float:
	if a == b:
		return 0.0
	return clamp((value - a) / (b - a), 0.0, 1.0)
	
	
#have to guess to make saves
func perform_guessing():
	if has_guessed:
		return
	var sum = pitches_left + pitches_middle + pitches_right
	if sum == 0:
		sum = 1
	var left_hist_weight = pitches_left / sum
	var mid_hist_weight = pitches_middle / sum
	var right_hist_weight = pitches_right / sum
	var roll = randf()
	if randf() < guess_preferences.memory: #use memory
		if roll < left_hist_weight:
			last_guess = "left"
			dive_left()
		elif roll < left_hist_weight + mid_hist_weight:
			last_guess = "middle"
			current_behavior = "defending"
		else:
			last_guess = "right"
			dive_right()
	else:
		if roll < guess_preferences.left:
			last_guess = "left"
			dive_left()
		elif roll < guess_preferences.left + guess_preferences.right:
			last_guess = "middle"
			if goalkeeping_preferences.charges_out:
				charge_middle()
			else:
				current_behavior = "defending"
		else:
			last_guess = "right"
			dive_right()
	print("dive: " + last_guess)
			
func dive_left():
	check_ball_close()
	current_behavior = "holding"
	hold_frame = 15
	var threeQuarters = (leftPost.x * 3 + global_position.x)/3
	var place = Vector2(threeQuarters, global_position.y)
	navigation_agent.target_position = place
	var dir = global_position.direction_to(place)
	velocity = dir * attributes.sprint_speed * attributes.blocking / 45 #2.2 for 99; 1 for 50
	move_and_slide()

func dive_right():
	check_ball_close()
	current_behavior = "holding"
	hold_frame = 15
	var threeQuarters = (rightPost.x * 3 + global_position.x)/3
	var place = Vector2(threeQuarters, global_position.y)
	navigation_agent.target_position = place
	var dir = global_position.direction_to(place)
	velocity = dir * attributes.sprint_speed * attributes.blocking / 45 #2.2 for 99; 1 for 50
	move_and_slide()

func charge_middle():
	check_ball_close()
	current_behavior = "holding"
	hold_frame = 20
	var spot = global_position.x/3 #3/4 to the middle of the field
	var place = Vector2(global_position.x, spot)
	navigation_agent.target_position = place
	var dir = global_position.direction_to(place)
	velocity = dir * attributes.sprint_speed * attributes.blocking / 45 #2.2 for 99; 1 for 50
	move_and_slide()
	
func save_pitch_from_ball(side: String):
	if side == "left":
		pitches_left += 1
	if side == "middle":
		pitches_middle += 1
	if side == "right":
		pitches_right += 1
		
func activate_special_ability():
	match special_ability:
		"maestro":
			is_maestro = true
		"machine":
			is_machine = true
		"spin_doctor":
			is_spin_doctor = true
	if status.groove <= 0:
		deactivate_special()
			
func is_special_active():
	if is_maestro:
		return true
	elif is_machine:
		return true
	elif is_spin_doctor:
		return true
	else:
		return false

func use_special_ability():
	if is_maestro: #maestro chews through groove fastest
		status.groove = status.groove - 0.18
	elif is_machine:
		status.groove = status.groove - 0.1
	else: #spin doctor is slower
		status.groove = status.groove - 0.05
	if status.groove <= 0:
		is_maestro = false
		is_machine = false
		is_spin_doctor = false
		
func deactivate_special():
	is_maestro = false
	is_machine = false
	is_spin_doctor = false
		
func ai_check_special_ability():
	if status.groove >= attributes.confidence / 2:
		var activate_chance = status.groove / attributes.confidence
		if randf() < activate_chance or desperate == true:
			print("AI using special ability")
			activate_special_ability()

#hold in place for x frames
func perform_holding(frame: int):
	if !ball: return
	check_ball_close()
	print("hold frame: ", hold_frame)
	if frame > 0:
		hold_frame = hold_frame - 1
		if global_position.distance_to(navigation_agent.target_position) < 3.0:
			current_behavior = "holding"
			velocity = Vector2.ZERO
		if global_position.distance_to(ball.global_position) < sqrt(attributes.reactions) - attributes.reactions/10:
			current_behavior = "defending"
			return
	else:
		current_behavior = "defending"
		
func _on_ball_emit_pitch_side():
	if is_controlling_player:
		return
	if ball.global_position.distance_squared_to(leftPost) <= ball.global_position.distance_squared_to(own_goal):
		save_pitch_from_ball("left")
		print("you're not beating me left next time")
	elif ball.global_position.distance_squared_to(rightPost) <= ball.global_position.distance_squared_to(own_goal):
		save_pitch_from_ball("right")
		print("you're not beating me right next time")
	else:
		save_pitch_from_ball("middle")
		print("you're not beating me middle next time")
		
func check_ball_close():
	if !ball:
		return false
	if ball.global_position.distance_to(own_goal) < max_goal_offset or ball.global_position.distance_to(global_position) < sqrt(attributes.reactions):
		current_behavior = "blocking"
		perform_blocking()
		return true
	else:
		return false
		
#if we're close enough to the ball and have no input, help the player out a little bit
func human_check_ball_close():
	if !ball: return
	if ball.global_position.distance_to(global_position) < sqrt(attributes.reactions):
		if !is_stunned and !is_dodging and velocity == Vector2(0,0):
			if is_machine:
				super_block(ball.global_position, ball.global_position)
			else:
				human_assisted_block(ball.global_position, ball.global_position)
				
func perform_pitch_defense():
	if !ball:
		current_behavior = "defending"
		return
	
	# Check if ball is in pitching state
	if ball.current_state != ball.BallState.PITCHING && ball.current_state != ball.BallState.SPECIAL_PITCH:
		current_behavior = "defending"
		return
	
	# Calculate prediction parameters based on blocking attribute
	var prediction_accuracy = 1.0 - (0.3 * (100 - attributes.blocking) / 100.0) #0.85 to 0.997
	var distance = ball.global_position.distance_to(own_goal)
	var margin_of_error = sqrt(distance) * 10 * (1.0 - prediction_accuracy) #15 to 0.3 at 100, 8 to 0.16 at 30
	var block_position
	if ball.current_state == ball.BallState.PITCHING:
		block_position = predict_normal_pitch_path(prediction_accuracy)
	else:  # Special pitch
		block_position = predict_special_pitch_path(prediction_accuracy)
	block_position.x += randf_range(-margin_of_error, margin_of_error)
	navigation_agent.target_position = block_position
	velocity = (block_position - global_position).normalized() * attributes.sprint_speed * BLOCKING_BONUS
	# Freeze briefly when ball changes direction significantly
	if ball_last_velocity != Vector2.ZERO:
		var direction_change = ball_last_velocity.normalized().angle_to(ball.linear_velocity.normalized())
		if abs(direction_change) > deg_to_rad(30):  # Significant direction change
			velocity = Vector2.ZERO
			reaction_timer = map_attribute_to_reaction_time(attributes.reactions)

func predict_normal_pitch_path(accuracy: float) -> Vector2:
	var goal_line_y = leftPost.y
	var current_pos = ball.global_position
	var current_vel = ball.linear_velocity
	var spin = ball.current_spin
	var time_to_goal = abs((goal_line_y - current_pos.y) / current_vel.y)
	var predicted_x = current_pos.x + current_vel.x * time_to_goal
	var curve_effect = spin * ball.spin_curve_factor * time_to_goal * accuracy
	predicted_x += curve_effect
	
	return Vector2(predicted_x, goal_line_y)

func predict_special_pitch_path(accuracy: float) -> Vector2:
	var goal_line_y = leftPost.y
	var current_pos = ball.global_position
	var current_vel = ball.linear_velocity
	var time_to_goal = abs((goal_line_y - current_pos.y) / current_vel.y)
	var predicted_x = current_pos.x + current_vel.x * time_to_goal
	var total_curve = 0.0
	var time_accumulated = 0.0
	var step = 0.1  # Time step in seconds
	
	# Simulate the special pitch curve sequence
	while time_accumulated < time_to_goal && ball.current_sp_index < ball.special_curves.size():
		var current_spin = ball.special_curves[ball.current_sp_index]
		var time_in_step = min(step, time_to_goal - time_accumulated)
		# Apply curve for this time segment
		total_curve += current_spin * ball.spin_curve_factor * time_in_step * accuracy
		time_accumulated += time_in_step
		# Advance to next curve segment if needed
		if time_accumulated > ball.special_frames[ball.current_sp_index] / 60.0:
			ball.current_sp_index = min(ball.current_sp_index + 1, ball.special_curves.size() - 1)
	predicted_x += total_curve
	
	return Vector2(predicted_x, goal_line_y)
