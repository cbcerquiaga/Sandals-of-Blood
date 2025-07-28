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
var target_position: Vector2 = Vector2.ZERO
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
	behaviors = ["waiting", "defending", "sweeping", "avoiding", "fencing", "attacking", "blocking", "returning"]
	current_behavior = "waiting"
	super._ready()
	position_type = "keeper"
	navigation_agent = $NavigationAgent2D
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 10.0

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
		#print("current behavior: ", current_behavior)
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
		#if !is_in_half():
			#if !is_stunned:
				#move_towards_half()
		if debug:
			current_debug_frame += 1
			if current_debug_frame >= debug_frames:
				current_debug_frame = 0
				print(current_behavior)
	else:
		if aim_target:
			aim_target.on = true
			aim = aim_target.global_position
		if Input.is_action_just_pressed("activate_special_ability"):
			if status.groove > 0:
				activate_special_ability()
				
		
		move_and_slide()

#region Behavior Implementations
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
	else:
		current_behavior = "defending"

func perform_sweeping():
	if !ball:
		current_behavior = "defending"
		return
	
	var distance_to_ball = global_position.distance_to(ball.global_position)
	var arrival_time = distance_to_ball / attributes.sprint_speed
	var anticipated_pos = ball.global_position + (ball_last_velocity * arrival_time)
	
	navigation_agent.target_position = anticipated_pos
	velocity = (anticipated_pos - global_position).normalized() * attributes.sprint_speed
	
	if distance_to_ball < 150:
		_make_sweeping_decision(anticipated_pos)

func perform_avoiding():
	var closest_opponent = get_closest_opponent()
	if !closest_opponent or global_position.distance_squared_to(closest_opponent.global_position) >= avoidance_weights.chill_threshold :
		current_behavior = "defending"
		return
	
	var threat = _calculate_forward_threat(closest_opponent)
	if threat > 0.9 and randf() < attributes.aggression / 99.0:
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
	
	fencing_timer += get_physics_process_delta_time()
	var current_dist = global_position.distance_to(current_opponent.global_position)
	var spacing_error = current_dist - fencing_params["ideal_distance"]
	
	if spacing_error > 0:  # Advance
		velocity = (current_opponent.global_position - global_position).normalized() * attributes.speed * fencing_params["advance_speed"]
	else:  # Retreat
		velocity = (global_position - current_opponent.global_position).normalized() * attributes.speed * fencing_params["retreat_speed"]
	
	if fencing_timer > fencing_params["attack_cooldown"]:
		_make_combat_decision(current_opponent.global_position, current_dist)

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

func _make_sweeping_decision(anticipated_pos: Vector2):
	var ball_speed = ball_last_velocity.length()
	var opponent_dist = global_position.distance_to(get_closest_opponent().global_position)
	var goal_dist = global_position.distance_to(own_goal)
	
	var strike_chance = 0.4*(1.0 - ball_speed/800.0) + (0.3*(1.0 - opponent_dist/300.0)) + (0.3*(1.0 - goal_dist/600.0))
	var keeper_bias = (attributes.aggression * 0.5 + attributes.confidence * 0.3) / 99.0
	_execute_sweeping_clearance(anticipated_pos)
	current_behavior = "defending"

func _execute_sweeping_clearance(pos: Vector2):
	if global_position.distance_to(ball.global_position) > 100:
		return
	
	var clear_dir = (ball.global_position - own_goal).normalized().rotated(deg_to_rad(randf_range(-30, 30)))
	ball.apply_force(clear_dir * (700 + 300 * attributes.aggression/99.0))
	time_since_last_touch = 0.0

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
func on_shot_at_goal(shot_from: Vector2, shot_direction: Vector2, shooter_team: int):
	if shooter_team == team: #not my problem
		return 
	var reaction_time = map_attribute_to_reaction_time(attributes.reactions)
	await get_tree().create_timer(reaction_time).timeout
	var intercept = shot_from + shot_direction * ((leftPost.y - shot_from.y) / shot_direction.y)
	var goal_width = leftPost.distance_to(rightPost)
	if !is_controlling_player and !is_stunned:
		ball_last_sighted = shot_from
		ball_direction_projection = shot_direction
		current_behavior = "blocking"
	elif !is_stunned and !is_dodging and velocity == Vector2(0,0) and intercept.distance_to(own_goal) < goal_width * 0.6:#slight buffer but has to be basically on goal
		if is_machine:
			super_block(shot_from, shot_direction, intercept)
		else:
			human_assisted_block(shot_from, shot_direction, intercept)

func human_assisted_block(shot_from: Vector2, shot_direction: Vector2, intercept: Vector2):
	print("human assisted block initiated")
	# Calculate the intercept point
	var diff = global_position.x - intercept.x
	var block_distance = (25*(attributes.blocking - 50))/49 + 5 #maximum distance we'll block
	# Determine target position
	if block_distance <= global_position.distance_to(intercept):
		if diff <= 0:
			human_block_target = Vector2(intercept.x + block_distance, global_position.y)
		else:
			human_block_target = Vector2(intercept.x - block_distance, global_position.y)
	else:
		human_block_target = global_position.direction_to(intercept).normalized() * block_distance + global_position
	is_human_blocking = true #override human input
	human_block_timer = HUMAN_BLOCK_DURATION
	navigation_agent.target_position = human_block_target
	var block_direction = global_position.direction_to(human_block_target).normalized()
	velocity = block_direction * attributes.sprint_speed * human_block_speed_multiplier

#improved block ability for if the keeper has the "shot swatter" special active
func super_block(shot_from: Vector2, shot_direction: Vector2, intercept: Vector2):
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
	var block_direction = global_position.direction_to(human_block_target).normalized()
	velocity = block_direction * attributes.sprint_speed * human_block_speed_multiplier
	return true  # Return true to indicate we're still overriding input
			
func perform_blocking():
	#print("Not in my house")
	var goal_line = leftPost.y
	var time_to_goal = (goal_line - ball_last_sighted.y) / ball_direction_projection.y
	var intercept = ball_last_sighted + (ball_direction_projection * time_to_goal)
	if intercept.distance_to(own_goal) > max_goal_offset:
		current_behavior = "defending"
		return
	var block_distance = (15*(attributes.blocking - 50))/49 + 5 #if 50, bd is 5; if 99, bd is 20
	var block_direction = global_position.direction_to(intercept).normalized()
	if block_distance <= global_position.distance_to(intercept):
		var diff = global_position.x - intercept.x
		if diff <= 0:
			navigation_agent.target_position = Vector2(intercept.x + block_distance, global_position.y)
		else:
			navigation_agent.target_position = Vector2(intercept.x - block_distance, global_position.y)
	else:
		navigation_agent.target_position = intercept
	velocity = block_direction * attributes.sprint_speed * BLOCKING_BONUS #slight bonus speed for blocking


func defending_behavior(delta: float):
	if !ball:
		return
	var goal_center: Vector2 = (leftPost + rightPost) / 2
	var goal_width: float = rightPost.distance_to(leftPost)
	
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
	
	# Determine target position based on ball proximity and projection
	var target_position: Vector2
	
	if ball.global_position.y < leftPost.y + 10 and abs(ball.global_position.x) > 35: 
		# Ball in corner - position near closest post
		var pos_check = (100 - attributes.positioning) / 10
		var positioning_variance = randf_range(-pos_check, pos_check)
		var aggression_variance = attributes.aggression / 20
		
		if leftPost.distance_squared_to(ball.global_position) < rightPost.distance_squared_to(ball.global_position):
			target_position = Vector2(leftPost.x + aggression_variance, leftPost.y + 5 + positioning_variance)
		else:
			target_position = Vector2(rightPost.x - aggression_variance, rightPost.y + 5 + positioning_variance)
			
	elif ball.global_position.distance_to(goal_center) < (attributes.reactions / 2):
		# Very close ball - go directly for it
		target_position = ball.global_position
		velocity = (target_position - global_position).normalized() * attributes.sprint_speed
		return
		
	else:
		# Use projected intercept for positioning
		if projected_intercept != Vector2.ZERO:
			# Position based on where ball is likely to end up
			var intercept_x = projected_intercept.x
			
			# Apply positioning skill variance
			var variance_x = (100 - attributes.positioning) / 10
			variance_x = randf_range(-variance_x, variance_x)
			intercept_x += variance_x
			
			# Clamp to reasonable goal defense area
			intercept_x = clamp(intercept_x, goal_center.x - max_goal_offset, goal_center.x + max_goal_offset)
			target_position = Vector2(intercept_x, leftPost.y + 10)
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
			target_position = Vector2(relative_x + variance_x, leftPost.y + 10)
	
	# Ensure we don't go too far from goal center
	var distance_from_center = abs(target_position.x - goal_center.x)
	if distance_from_center > max_goal_offset:
		target_position.x = goal_center.x + sign(target_position.x - goal_center.x) * max_goal_offset
	
	navigation_agent.target_position = target_position
	velocity = (target_position - global_position).normalized() * attributes.speed

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
			current_behavior = "defending"
		else:
			last_guess = "right"
			dive_right()
	print("dive: " + last_guess)
			
func dive_left():
	current_behavior = "holding"
	hold_frame = 15
	var threeQuarters = (leftPost.x * 3 + global_position.x)/3
	var place = Vector2(threeQuarters, global_position.y)
	navigation_agent.target_position = place
	var dir = global_position.direction_to(place)
	velocity = dir * attributes.sprint_speed * attributes.blocking / 45 #2.2 for 99; 1 for 50
	move_and_slide()

func dive_right():
	current_behavior = "holding"
	hold_frame = 15
	var threeQuarters = (rightPost.x * 3 + global_position.x)/3
	var place = Vector2(threeQuarters, global_position.y)
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
	status.groove = status.groove - 0.25
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
