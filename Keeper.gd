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

@export var fencing_params := {
	"ideal_distance": 12.0,
	"advance_speed": attributes.speed * 0.75,
	"retreat_speed": attributes.speed,
	"attack_cooldown": 1.0,
	"ball_proximity_threshold": 30.0#TODO: base on reactions
}

@export var attack_params := {
	"attack_range": 100.0,
	"target_switch_threshold": 50.0,
	"cooldown_time": 0.8
}

# State
var current_behavior: String = "waiting"
var own_goal: Vector2
var opp_goal: Vector2
var leftPost: Vector2
var rightPost: Vector2
var left_wall: StaticBody2D
var right_wall: StaticBody2D
var back_wall: StaticBody2D
var attack_target: Player = null
var current_opponent: Player = null
var fencing_timer: float = 0.0
var attack_cooldown: float = 0.0
var ball_last_position: Vector2
var ball_last_velocity: Vector2
var time_since_last_touch: float = 0.0
var buddyLF
var buddyRF
var oppLF
var oppRF
var oppKeeper

# Navigation
var navigation_agent: NavigationAgent2D

func _ready():
	debug = false
	super._ready()
	position_type = "keeper"
	navigation_agent = $NavigationAgent2D
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 10.0

func _physics_process(delta):
	super._physics_process(delta)
	
	if not is_controlling_player and can_move:
		time_since_last_touch += delta
		
		# Update ball tracking
		if ball:
			ball_last_velocity = (ball.global_position - ball_last_position) / delta
			ball_last_position = ball.global_position
		
		match current_behavior:
			"waiting":
				perform_waiting()
			"defending":
				perform_defending()
				check_state()
			"striking":
				perform_striking()
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
				
		if debug:
			current_debug_frame += 1
			if current_debug_frame >= debug_frames:
				current_debug_frame = 0
				print(current_behavior)
		
		move_and_slide()

#region Behavior Implementations
func perform_waiting():
	"""Waiting behavior - the keeper does nothing in this state"""
	navigation_agent.target_position = global_position
	velocity = Vector2.ZERO
	
	# Tiny idle movements
	if randf() < 0.01:
		var tiny_wander = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		navigation_agent.target_position = tiny_wander
	
	## Transition if ball comes close
	#if ball and global_position.distance_to(ball.global_position) < 600:
		#current_behavior = "defending"

func perform_defending():
	"""Defending behavior - positions the keeper along defensive arc"""
	if !ball or !leftPost or !rightPost:
		return
	
	var goalLine = [leftPost, rightPost]
	var ballPath = [ball.global_position, Geometry2D.get_closest_point_to_segment(ball.global_position, goalLine[0], goalLine[1])]
	var baseTargetPos = _calculate_arc_intersection(goalLine, ballPath)
	var adjustedTargetPos = _apply_anticipation_adjustments(baseTargetPos)
	
	navigation_agent.target_position = adjustedTargetPos
	velocity = (adjustedTargetPos - global_position).normalized() * attributes.speed

func check_state():
	"""Determines when to transition from defending to other states"""
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
	
	# Check for blocking conditions (urgent defense)
	if (ball_speed > 500 and goal_threat > 0.7) or ball_dist_to_goal < keeper_dist_to_goal:
		current_behavior = "blocking"
		return
	
	# Check for striking conditions (ball control)
	if keeper_dist_to_ball < attributes.aggression/4: #12.5 for 50, 20 for 80, 25 for 99
		print(str(keeper_dist_to_ball))
		current_behavior = "striking"
		return
	
	# Check for avoiding conditions (forward pressure)
	var closest_opponent = get_closest_opponent()
	if closest_opponent and global_position.distance_to(closest_opponent.global_position) < avoidance_weights["panic_threshold"]:
		current_behavior = "avoiding"
		return
	
	# Check for sweeping conditions (ball stagnation)
	var sweep_chance = 0.0
	sweep_chance += 0.4 * (1.0 - clamp(ball_speed / sweeping_params.slow, 0.0, 1.0))  # Slow ball
	sweep_chance += 0.3 * (1.0 - abs(ball_direction.x))  # Lateral movement
	sweep_chance += 0.3 * clamp(time_since_last_touch / sweeping_params.grumpy_frames, 0.0, 1.0)  # Time since touch
	
	if keeper_dist_to_ball <= sweeping_params.max_distance and keeper_dist_to_ball >= sweeping_params.min_distance:
		if randf() < sweep_chance * (attributes.aggression / 99.0):
			current_behavior = "sweeping"

func perform_blocking():
	"""Blocking behavior - intercepts ball path to goal"""
	if !ball or !leftPost or !rightPost:
		current_behavior = "defending"
		return
	
	var goalLine = [leftPost, rightPost]
	var ballPath = [ball.global_position, Geometry2D.get_closest_point_to_segment(ball.global_position, goalLine[0], goalLine[1])]
	var pathClosest = Geometry2D.get_closest_point_to_segment(global_position, ballPath[0], ballPath[1])
	var blockingPos = pathClosest.lerp(ballPath[1], 0.2)  # 20% toward goal
	
	navigation_agent.target_position = blockingPos
	velocity = (blockingPos - global_position).normalized() * attributes.sprint_speed
	
	if global_position.distance_to(ball.global_position) < 100:
		current_behavior = "striking"

func perform_striking():
	"""Striking behavior - makes calculated decisions on where to send the ball"""
	if !ball or !opp_goal:
		current_behavior = "defending"
		return
	
	var target_pos = _determine_strike_target()
	var intercept_point = _calculate_intercept_striking(target_pos)
	
	if !intercept_point:
		current_behavior = "defending"
		return
	
	# Calculate strike vector (direction and power)
	var strike_power = 800 + (200 * attributes.aggression / 99.0)
	var strike_vector = (target_pos - intercept_point).normalized() * strike_power
	
	# Move to intercept point
	navigation_agent.target_position = intercept_point
	var desired_velocity = (intercept_point - global_position).normalized() * attributes.sprint_speed
	velocity = velocity.lerp(desired_velocity, 0.4)  # Aggressive movement
	
	# Execute strike when in position
	if global_position.distance_to(intercept_point) < 30:
		_execute_strike(strike_vector)
		current_behavior = "defending"  # Return to defending after strike

func _calculate_intercept_striking(target_pos: Vector2) -> Variant:
	"""
	Calculates optimal intercept point for striking the ball toward target.
	Returns Vector2 position or null if intercept is unreachable.
	"""
	if !ball:
		return null
	
	# Predict ball position 0.3-0.8 seconds in future (based on reactions)
	var prediction_time = clamp(0.8 - (attributes.reactions / 200.0), 0.3, 0.8)
	var predicted_ball_pos = ball.global_position + ball_last_velocity * prediction_time
	
	# Calculate ideal striking position (slightly behind ball's path to target)
	var ball_to_target = (target_pos - predicted_ball_pos).normalized()
	var intercept_point = predicted_ball_pos - (ball_to_target * 25.0)  # Back off slightly
	
	# Verify this position is reachable
	if intercept_point.distance_to(global_position) > 500:  # Too far to attempt
		return null
	
	# Adjust for keeper's current momentum
	if velocity.length() > 100:
		var momentum_adjustment = velocity.normalized() * 20.0
		intercept_point += momentum_adjustment
	
	# Ensure we're not trying to intercept behind our own goal
	var goal_center = (leftPost + rightPost) / 2
	if (intercept_point - goal_center).dot((target_pos - goal_center).normalized()) < -0.5:
		return null
	
	return intercept_point

func perform_sweeping():
	"""Sweeping behavior - aggressively pursues ball with anticipation"""
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
	"""Avoiding behavior - evades opposing forwards while positioning"""
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
		attempt_dodge()

func perform_fencing():
	"""Fencing behavior - duels with a specific forward"""
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
		_make_combat_decision(current_dist)

func perform_attacking():
	"""Attacking behavior - aggressively charges and attacks forwards"""
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
		_execute_attack()
#endregion

#region Helper Functions
func _calculate_arc_intersection(goalLine: Array, ballPath: Array) -> Vector2:
	"""Calculates intersection with defensive arc"""
	var arcHeight = 15 * (1.0 - attributes.aggression/99.0) * (0.5 + attributes.confidence/200.0)
	#print("arc height: " + str(arcHeight))
	var controlPoint = (goalLine[0] + goalLine[1]) / 2 - Vector2(0, arcHeight)
	var t = _estimate_bezier_intersection(goalLine[0], controlPoint, goalLine[1], ballPath[0], ballPath[1])
	return _quadratic_bezier_point(goalLine[0], controlPoint, goalLine[1], t)
	
func _estimate_bezier_intersection(p0: Vector2, p1: Vector2, p2: Vector2, line_a: Vector2, line_b: Vector2) -> float:
	"""
	Estimates the t value (0-1) where a quadratic Bezier curve intersects with a line segment.
	Returns the t value of the closest estimated intersection point.
	
	Parameters:
		p0, p1, p2: Control points of the quadratic Bezier curve
		line_a, line_b: Points defining the line segment to test against
	"""
	var best_t = 0.5  # Default midpoint if no better intersection found
	var min_dist = INF  # Track closest distance found
	
	# Sample 11 points along the curve (0.0 to 1.0 in 0.1 increments)
	for i in range(11):
		var t = i / 10.0
		# Calculate point on Bezier curve at t
		var q0 = p0.lerp(p1, t)
		var q1 = p1.lerp(p2, t)
		var curve_point = q0.lerp(q1, t)
		
		# Find closest point on line segment to this curve point
		var line_point = Geometry2D.get_closest_point_to_segment(curve_point, line_a, line_b)
		var dist = curve_point.distance_to(line_point)
		
		# Keep track of the closest point
		if dist < min_dist:
			min_dist = dist
			best_t = t
	
	# If we found a reasonably close point, do a refined search near it
	if min_dist < 10.0:  # 10 pixel threshold for "close enough"
		# Search around the best t with smaller steps
		var refine_start = max(best_t - 0.1, 0.0)
		var refine_end = min(best_t + 0.1, 1.0)
		
		for i in range(11):
			var t = refine_start + (i / 10.0) * (refine_end - refine_start)
			var q0 = p0.lerp(p1, t)
			var q1 = p1.lerp(p2, t)
			var curve_point = q0.lerp(q1, t)
			
			var line_point = Geometry2D.get_closest_point_to_segment(curve_point, line_a, line_b)
			var dist = curve_point.distance_to(line_point)
			
			if dist < min_dist:
				min_dist = dist
				best_t = t
	
	return best_t
	
func _quadratic_bezier_point(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	"""
	Calculates a point on a quadratic Bezier curve at parameter t (0-1)
	
	Parameters:
		p0: Start point
		p1: Control point
		p2: End point
		t: Interpolation parameter (0-1)
		
	Returns:
		Vector2 position on the curve at t
	"""
	# First linear interpolation between p0-p1 and p1-p2
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	
	# Final interpolation between the intermediate points
	return q0.lerp(q1, t)

func _apply_anticipation_adjustments(basePos: Vector2) -> Vector2:
	"""Adjusts position based on ball and opponent predictions"""
	var adjustedPos = basePos
	
	if !_is_ball_near_wall():
		var trajectoryInfluence = 0.5 * (attributes.reactions / 100.0)
		adjustedPos = adjustedPos.lerp(ball.global_position + ball_last_velocity * trajectoryInfluence, 0.3)
	
	var nearestOpponent = get_closest_opponent()
	if nearestOpponent:
		var opponentInfluence = 0.4 * (1.0 - attributes.toughness/100.0)
		adjustedPos += (adjustedPos - nearestOpponent.global_position).normalized() * 10.0 * opponentInfluence
	
	var randomFactor = 1.0 - (attributes.positioning / 100.0)
	adjustedPos += Vector2(randf_range(-10, 10) * randomFactor, randf_range(-10, 10) * randomFactor)
	
	var goalCenter = (leftPost + rightPost) / 2
	if adjustedPos.distance_to(goalCenter) > attributes.aggression:
		#print("adjusted position")
		adjustedPos = (goalCenter + adjustedPos) / (attributes.aggression / 50)
	
	return adjustedPos

func _make_sweeping_decision(anticipated_pos: Vector2):
	"""Decides whether to strike or clear during sweeping"""
	var ball_speed = ball_last_velocity.length()
	var opponent_dist = global_position.distance_to(get_closest_opponent().global_position)
	var goal_dist = global_position.distance_to(own_goal)
	
	var strike_chance = 0.4*(1.0 - ball_speed/800.0) + (0.3*(1.0 - opponent_dist/300.0)) + (0.3*(1.0 - goal_dist/600.0))
	var keeper_bias = (attributes.aggression * 0.5 + attributes.confidence * 0.3) / 99.0
	
	if (strike_chance + keeper_bias) > 0.5:
		current_behavior = "striking"
	else:
		_execute_sweeping_clearance(anticipated_pos)
		current_behavior = "defending"

func _execute_sweeping_clearance(pos: Vector2):
	"""Performs a clearance while in motion"""
	if global_position.distance_to(ball.global_position) > 100:
		return
	
	var clear_dir = (ball.global_position - own_goal).normalized().rotated(deg_to_rad(randf_range(-30, 30)))
	ball.apply_force(clear_dir * (700 + 300 * attributes.aggression/99.0))
	time_since_last_touch = 0.0

func _determine_strike_target() -> Vector2:
	"""Determines where to aim the ball"""
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
	"""Applies force to ball when striking"""
	if global_position.distance_to(ball.global_position) < 50:
		ball.apply_force(strike_vector)
		time_since_last_touch = 0.0

func _make_combat_decision(current_dist: float):
	"""Decides to attack or dodge during fencing"""
	var attack_prob = (0.4*attributes.aggression/99.0) + (0.3*(1.0 - current_dist/fencing_params["ideal_distance"]))
	
	if attack_prob > 0.65:
		super.attempt_attack()
		fencing_timer = 0.0
		velocity += (global_position - current_opponent.global_position).normalized() * 100.0
	else:
		attempt_dodge()
		fencing_timer = fencing_params["attack_cooldown"] * 0.5

func _execute_attack():
	"""Performs attack against current target"""
	super.attempt_attack()
	attack_cooldown = attack_params["cooldown_time"]
	
	if attack_target.is_stunned:
		attack_target = _find_secondary_target()
		if !attack_target:
			current_behavior = "defending"
#endregion

#region Utility Functions
func _is_ball_near_wall() -> bool:
	"""Checks if ball is near any wall"""
	return (ball.global_position.distance_to(left_wall.global_position) < 100 or
			ball.global_position.distance_to(right_wall.global_position) < 100 or
			ball.global_position.distance_to(back_wall.global_position) < 100)

func _calculate_forward_threat(forward: Player) -> float:
	"""Calculates threat level from a forward (0-1)"""
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
		
func attempt_dodge():
	if status.boost > 15:
		super.start_spin()

func _calculate_avoidance_position(threat_left: float, threat_right: float) -> Vector2:
	"""Calculates optimal avoidance position"""
	var goal_center = (leftPost + rightPost) / 2
	var repulsion = Vector2.ZERO
	
	if oppLF and threat_left > 0:
		repulsion += (global_position - oppLF.global_position).normalized() * threat_left * avoidance_weights["forward_proximity"]
	
	if oppRF and threat_right > 0:
		repulsion += (global_position - oppRF.global_position).normalized() * threat_right * avoidance_weights["forward_proximity"]
	
	var target_pos = global_position + (repulsion + (goal_center - global_position).normalized() * avoidance_weights["goal_proximity"]) * 200.0
	return goal_center + (target_pos - goal_center).limit_length(leftPost.distance_to(goal_center) * 1.5)

func _should_break_fencing() -> bool:
	"""Checks if fencing should be interrupted"""
	return ball and global_position.distance_to(ball.global_position) < fencing_params["ball_proximity_threshold"] * (1.1 - attributes.reactions/100.0)

func _select_attack_target() -> Player:
	"""Selects most appropriate forward to attack"""
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
	"""Finds another forward to attack after a stun"""
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
	"""Checks if direct shot at goal is viable"""
	if _path_clearness(global_position, opp_goal) > (0.7 - (0.3 * attributes.aggression/99.0)) or oppKeeper.global_position.distance_to(opp_goal) > 250:
		return true
	else:
		return false

func _calculate_bank_shot_target() -> Vector2:
	"""Calculates target for bank shot off walls"""
	var use_left = randf() > 0.5
	var wall_pos = left_wall.global_position if use_left else right_wall.global_position
	var wall_normal = Vector2(1, 0) if use_left else Vector2(-1, 0)
	
	if randf() < 0.6:  # One-bank
		return (Vector2(opp_goal.x + (100 if use_left else -100), opp_goal.y - 150) - wall_pos).bounce(wall_normal) * 1.5
	else:  # Two-bank
		return (Vector2(right_wall.global_position.x if use_left else left_wall.global_position.x, back_wall.global_position.y) - wall_pos).bounce(wall_normal) * 1.8

func _find_pass_target() -> Variant:
	"""Finds viable pass target or returns null"""
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
	
	return options[weighted_random_choice(range(options.size()), weights)] if !options.is_empty() else null

func _calculate_miss_target() -> Vector2:
	"""Calculates target for intentional miss"""
	var use_left = randf() > 0.5
	return Vector2(
		left_wall.global_position.x + 100 if use_left else right_wall.global_position.x - 100,
		back_wall.global_position.y * 0.8
	)

func _calculate_strike_parameters(target_pos: Vector2) -> Variant:
	"""Calculates intercept point and strike vector"""
	var ball_future = ball.global_position + ball_last_velocity * 1.0
	var strike_dir = (target_pos - ball_future).normalized()
	var intercept = ball_future - (strike_dir * 30.0)
	
	if intercept.distance_to(global_position) > 500:
		return null
	
	return [intercept, strike_dir * (800 + 200 * attributes.aggression/99.0)]

func _path_clearness(from_pos: Vector2, to_pos: Vector2) -> float:
	"""Returns 0-1 value representing path clearness"""
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
	"""Returns a random option with weighted probability"""
	var total = weights.reduce(func(a, b): return a + b, 0.0)
	var roll = randf() * total
	var cumulative = 0.0
	
	for i in options.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return options[i]
	
	return options[0]
#endregion
