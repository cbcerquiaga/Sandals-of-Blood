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

# State
var current_behavior: String = "waiting"
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
var oppLF
var oppRF
var oppKeeper

# defending the ball
var reaction_timer: float = 0
var reacting: bool = false
var last_ball_direction: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var current_position: Vector2 = Vector2.ZERO
# Constants
const MAX_REACTION_TIME: float = 0.5  # seconds
const MIN_REACTION_TIME: float = 0.1  # seconds
const BASE_AGGRESSION_DISTANCE: float = 100.0  # pixels
const POSITIONING_VARIANCE: float = 30.0  # max variance in pixels
const ANTICIPATION_DISTANCE: float = 200.0  # how far ahead to look for ball path

# Navigation
var navigation_agent: NavigationAgent2D

func _ready():
	debug = false
	behaviors = ["waiting", "defending", "sweeping", "avoiding", "fencing", "attacking"]
	super._ready()
	attributes.blocking = 85 #nice and wide
	self.scale.x = 1 * (attributes.blocking/50)
	position_type = "keeper"
	navigation_agent = $NavigationAgent2D
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 10.0

func _physics_process(delta):
	super._physics_process(delta)
	if !can_move:
		velocity = Vector2.ZERO
		return
	
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
				defending_behavior(delta)
				check_state()
			#"blocking":
				#perform_blocking()
			"sweeping":
				perform_sweeping()
			"avoiding":
				perform_avoiding()
			"fencing":
				perform_fencing()
			"attacking":
				perform_attacking()
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
		


func check_state():
	"""Determines when to transition from defending to other states"""
	if !ball:
		return
	if current_behavior == "waiting": #sit down and wait!
		return
		
	#DEBUG TODO: remove
	#current_behavior = "defending"
	return
	
	var ball_speed = ball_last_velocity.length()
	var ball_to_goal = (own_goal - ball.global_position).normalized()
	var ball_direction = ball_last_velocity.normalized()
	var goal_threat = ball_direction.dot(ball_to_goal)
	
	var ball_dist_to_goal = ball.global_position.distance_squared_to(own_goal)
	var keeper_dist_to_goal = global_position.distance_squared_to(own_goal)
	var keeper_dist_to_ball = global_position.distance_to(ball.global_position)
	
	# Check for blocking conditions (urgent defense) #TODO: see if this is necessary, rework if it is
	#if (ball_speed > 500 and goal_threat > 0.7) or ball_dist_to_goal < keeper_dist_to_goal:
		#current_behavior = "blocking"
		#return
	
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
		super.attempt_dodge()

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
		_make_combat_decision(current_opponent.global_position, current_dist)

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
		_execute_attack(attack_target.global_position)
#endregion

func _make_sweeping_decision(anticipated_pos: Vector2):
	"""Decides whether to strike or clear during sweeping"""
	var ball_speed = ball_last_velocity.length()
	var opponent_dist = global_position.distance_to(get_closest_opponent().global_position)
	var goal_dist = global_position.distance_to(own_goal)
	
	var strike_chance = 0.4*(1.0 - ball_speed/800.0) + (0.3*(1.0 - opponent_dist/300.0)) + (0.3*(1.0 - goal_dist/600.0))
	var keeper_bias = (attributes.aggression * 0.5 + attributes.confidence * 0.3) / 99.0
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

func _execute_attack(target: Vector2):
	"""Performs attack against current target"""
	super.attempt_attack(target)
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

func defending_behavior(delta: float):
	if !ball:
		return
	
	# Calculate goal characteristics
	var goal_center: Vector2 = (leftPost + rightPost) / 2
	var goal_width: float = rightPost.distance_to(leftPost)
	
	# Get ball position and velocity
	var ball_pos: Vector2 = ball.global_position
	var ball_vel: Vector2 = ball.linear_velocity
	
	#initial position: goal line, x as far as ball is across field
	var ball_field_distance
	if fieldType == "road":
		ball_field_distance = ball.global_position.x/57.0
	else:
		ball_field_distance = ball.global_position.x/100
	var relative_x = ball_field_distance * goal_width
	if ball.global_position.y < leftPost.y + 10 and abs(ball.global_position.x) > 35: #in teh corner
		var pos_check =  (100-attributes.positioning)/10
		var positioning_variance = randf_range(0- pos_check, pos_check)
		var aggression_variance = attributes.aggression/20
		if leftPost.distance_squared_to(ball.global_position) < rightPost.distance_squared_to(ball.global_position):
			navigation_agent.target_position = Vector2(leftPost.x + aggression_variance, leftPost.y + 5 + positioning_variance)
		else:
			navigation_agent.target_position = Vector2(rightPost.x - aggression_variance, rightPost.y + 5 + positioning_variance)
	elif ball.global_position.distance_to(goal_center) < (attributes.reactions / 2): #faster reactions = more saves
		navigation_agent.target_position = ball.position
		velocity = (navigation_agent.target_position - global_position).normalized() * attributes.sprint_speed
		return
	else: #far away, passive position
		#account for positioning skill
		var variance_x = (100 - attributes.positioning)/10
		variance_x = randf_range(0 -variance_x, variance_x)
		navigation_agent.target_position = Vector2(relative_x + variance_x, leftPost.y + 10)

	#project a path of the ball
	
	#consider that it might reflect off of a wall or an opposing forward
	
	#if the ball changes directions, freeze in place for a moment
	#length of freeze depends on attributes.reactions
	
	#goal position based on projection and attributes.positioning
	
	#make sure total distance to center of goal is less than 20
	
	#move
	velocity = (navigation_agent.target_position - global_position).normalized() * attributes.speed



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
