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

#sweeping specific behavior
var sweep_state: String = "none"  # "approaching", "retreating", "bailed"
var sweep_target: Vector2 = Vector2.ZERO
var sweep_commit_point: Vector2 = Vector2.ZERO  #starting point when deciding to commit to sweeping up a loose ball
var frames_since_sweep_start: int = 0
const SWEEP_BAILOUT_CHECK_FREQUENCY: int = 5  #frames per bailout decision check

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
const DIVE_HESITATION_FRAMES = 15  # Base hesitation before committing to dive
const CONTACT_EVALUATION_DISTANCE = 100.0  # Distance to consider attacking
const GUARD_PROTECTION_WEIGHT = 0.6  # How much contact-averse keepers value guard positioning
const ANTICIPATION_THRESHOLD: float = 300.0  # Distance to consider opponent as passing target
const PASS_INTERCEPT_RANGE: float = 80.0  # How close opponent needs to be to ball path

# Anticipation variables
var anticipated_shooter: Player = null
var anticipation_frames: int = 0
var last_anticipated_position: Vector2 = Vector2.ZERO
var forced_guess: String = ""
var lf_shot_history: Array = []
var rf_shot_history: Array = []

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
	if current_behavior in ["run_gauntlet", "be_gauntlet"]:#gauntlet behavior supercedes anything else
		return
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
			return  #skip normal input processing while blocking
	if is_special_active():
		use_special_ability()
	
	
	if not is_controlling_player and can_move:
		#print("current behavior: ", current_behavior)
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
		if current_behavior == "waiting" and opposing_keeper.current_behavior != "waiting":
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
	if current_behavior == "waiting":
		return
	
	var ball_speed = ball_last_velocity.length()
	var ball_to_goal = (own_goal - ball.global_position).normalized()
	var ball_direction = ball_last_velocity.normalized()
	var goal_threat = ball_direction.dot(ball_to_goal)
	
	var ball_dist_to_goal = ball.global_position.distance_to(own_goal)
	var keeper_dist_to_ball = global_position.distance_to(ball.global_position)
	if ball.current_state == ball.BallState.PITCHING or ball.current_state == ball.BallState.SPECIAL_PITCH:
		current_behavior = "pitch_defense"
		return
	if goalkeeping_preferences.likes_contact:
		var should_attack = _decide_attack_opponent()
		if should_attack:
			current_behavior = "attacking"
			return
	var closest_opponent = get_closest_opponent()
	if closest_opponent:
		var opp_distance = global_position.distance_to(closest_opponent.global_position)
		if goalkeeping_preferences.likes_contact:
			if opp_distance < avoidance_weights["panic_threshold"]:
				var attack_chance = get_buffed_attribute("aggression") / 99.0
				if randf() < attack_chance and status.anger >= 100:
					current_behavior = "fencing"
					current_opponent = closest_opponent
					return
		else:
			if opp_distance < avoidance_weights["panic_threshold"]:
				current_behavior = "avoiding"
				return
	if goal_threat > 0.6 and ball_speed > 100 and ball_dist_to_goal < get_buffed_attribute("reactions"):
		current_behavior = "blocking"
		ball_last_sighted = ball.global_position
		ball_direction_projection = ball_direction
		return

	if keeper_dist_to_ball < 30 + get_buffed_attribute("aggression"):
		_make_sweeping_decision()
	else:
		current_behavior = "defending"

func _calculate_ball_intercept_with_bounces() -> Vector2:
	if !ball or ball_last_velocity.length() < 50:
		return ball.global_position
	var current_pos = ball.global_position
	var current_vel = ball_last_velocity
	var keeper_speed = get_buffed_attribute("sprint_speed")
	var max_bounces = 2
	var bounce_count = 0
	var goal_line_y = leftPost.y
	var buffer = 5.0  #stay in front of the damned goal
	while bounce_count <= max_bounces:
		var distance_to_intercept = global_position.distance_to(current_pos)
		var keeper_time = distance_to_intercept / keeper_speed
		var ball_future_pos = current_pos + current_vel * keeper_time
		var wall_collision = _check_wall_collision(current_pos, current_vel, keeper_time)
		if wall_collision.has("collision"):
			current_pos = wall_collision["position"]
			current_vel = wall_collision["new_velocity"]
			bounce_count += 1
		else:
			if sign(goal_line_y) > 0:  # Bottom goal
				ball_future_pos.y = min(ball_future_pos.y, goal_line_y - buffer)
			else:  # Top goal
				ball_future_pos.y = max(ball_future_pos.y, goal_line_y + buffer)
			return ball_future_pos
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
	if threat > 0.9 and randf() < get_buffed_attribute("aggression") / 100.0:
		if status.anger + get_buffed_attribute("aggression") >= 150: #150 instead of 100 because the keeper needs to focus on the goal
			current_behavior = "fencing"
			current_opponent = closest_opponent
			return
	var avoidance_pos = _calculate_avoidance_position(threat, 0.0)
	navigation_agent.target_position = avoidance_pos
	velocity = (avoidance_pos - global_position).normalized() * get_buffed_attribute("speed")
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
		#if current_opponent.current_behavior != "brawling":
			#current_opponent.jumped_brawl(self)
		brawl_footwork(current_opponent)
	else:
		navigation_agent.target_position = current_opponent.global_position
		velocity = global_position.direction_to(navigation_agent.target_position).normalized() * get_buffed_attribute("speed")

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
	
	velocity = (attack_target.global_position - global_position).normalized() * get_buffed_attribute("sprint_speed")
	
	if global_position.distance_to(attack_target.global_position) < attack_params["attack_range"]:
		_execute_attack(attack_target.global_position)
#endregion

func _make_sweeping_decision():
	if !goalkeeping_preferences.sweeper_keeper:
		current_behavior = "defending"
		return
	#don't sweep if ball is on wrong side of field
	if (ball.global_position.y < 0 and own_goal.y > 0) or (ball.global_position.y > 0 and own_goal.y < 0):
		current_behavior = "defending"
		return
	
	var ball_speed = ball_last_velocity.length()
	var closest_opponent = get_closest_opponent()
	var opponent_dist = global_position.distance_to(closest_opponent.global_position) if closest_opponent else 999999
	var goal_dist = global_position.distance_to(own_goal)
	var anticipated_ball_pos = _calculate_sweep_intercept()
	var anticipated_distance = global_position.distance_to(anticipated_ball_pos)
	var clearness = _path_clearness_to_ball(global_position, anticipated_ball_pos)
	var positioning_skill = get_buffed_attribute("positioning")
	var judgment_quality = positioning_skill / 99.0
	var dist_modifier = 1.25 if goal_dist < opponent_dist else 0.75
	var corner_modifier = 2.0 if abs(ball.global_position.x - own_goal.x) > 80 else 1.0
	var keeper_bias = (get_buffed_attribute("aggression") * 0.7 + judgment_quality * 0.3)
	var time_modifier = 1.0
	if ball.last_touched_time > 180:
		time_modifier = 1.2
	elif ball.last_touched_time > 90:
		time_modifier = 1.1
	var distance_viable = true
	if anticipated_distance > sweeping_params["max_distance"]:
		distance_viable = false
		clearness *= 0.3
	elif anticipated_distance < sweeping_params["min_distance"]:
		distance_viable = false
	if sign(anticipated_ball_pos.y) != sign(own_goal.y):
		clearness *= 0.1
	var choice = clearness * keeper_bias * dist_modifier * corner_modifier * time_modifier / 100.0
	
	if distance_viable and randf() < choice:
		sweep_state = "approaching"
		sweep_commit_point = global_position
		sweep_target = anticipated_ball_pos
		frames_since_sweep_start = 0
		current_behavior = "sweeping"
		print("CGimme that ball! Target: ", sweep_target, " | Clearness: ", clearness)
	else:
		current_behavior = "defending"

func _calculate_sweep_intercept() -> Vector2:
	if !ball or ball_last_velocity.length() < 50:
		return ball.global_position
	
	var positioning_skill = get_buffed_attribute("positioning")
	var reactions_skill = get_buffed_attribute("reactions") 
	var prediction_quality = (positioning_skill + reactions_skill) / 2.0 / 99.0  #0 to 1
	
	var current_pos = ball.global_position
	var current_vel = ball_last_velocity
	var keeper_speed = get_buffed_attribute("sprint_speed")
	var simulation_steps = int(60 * prediction_quality)  #0-60 
	var best_intercept = current_pos
	var best_time_diff = 999999.0
	
	for step in range(1, simulation_steps):
		var time_elapsed = step / 60.0  #frames to seconds
		var projected_pos = current_pos + current_vel * time_elapsed
		projected_pos = _apply_wall_bounces_to_projection(current_pos, current_vel, time_elapsed)
		var keeper_distance = global_position.distance_to(projected_pos)
		var keeper_time = keeper_distance / keeper_speed
		var time_diff = abs(keeper_time - time_elapsed)
		if time_diff < best_time_diff:
			best_time_diff = time_diff
			best_intercept = projected_pos
		current_vel *= 0.98
		if current_vel.length() < 50:
			break
	
	var error_margin = (100 - positioning_skill) * 0.8  #0-80 pixels of error
	best_intercept.x += randf_range(-error_margin, error_margin)
	best_intercept.y += randf_range(-error_margin * 0.5, error_margin * 0.5)
	var goal_line_y = leftPost.y
	if sign(goal_line_y) > 0:
		best_intercept.y = min(best_intercept.y, goal_line_y)
	else:
		best_intercept.y = max(best_intercept.y, goal_line_y)
	return best_intercept

func _apply_wall_bounces_to_projection(start_pos: Vector2, velocity: Vector2, time: float) -> Vector2:
	var pos = start_pos
	var vel = velocity
	var remaining_time = time
	var bounces = 0
	var max_bounces = 3
	
	while remaining_time > 0 and bounces < max_bounces:
		var next_pos = pos + vel * remaining_time
		var collision = _find_nearest_wall_collision(pos, vel, remaining_time)
		if collision.has("time") and collision["time"] < remaining_time:
			pos = collision["position"]
			vel = collision["new_velocity"]
			remaining_time -= collision["time"]
			bounces += 1
		else:
			pos = next_pos
			break
	return pos

func _find_nearest_wall_collision(pos: Vector2, vel: Vector2, max_time: float) -> Dictionary:
	var nearest_collision = {}
	var nearest_time = max_time
	if vel.x < 0 and left_wall:
		var wall_x = left_wall.global_position.x + 20
		var time_to_wall = (wall_x - pos.x) / vel.x
		if time_to_wall > 0 and time_to_wall < nearest_time:
			nearest_time = time_to_wall
			nearest_collision = {
				"time": time_to_wall,
				"position": Vector2(wall_x, pos.y + vel.y * time_to_wall),
				"new_velocity": Vector2(-vel.x * 0.8, vel.y)
			}
	if vel.x > 0 and right_wall:
		var wall_x = right_wall.global_position.x - 20
		var time_to_wall = (wall_x - pos.x) / vel.x
		if time_to_wall > 0 and time_to_wall < nearest_time:
			nearest_time = time_to_wall
			nearest_collision = {
				"time": time_to_wall,
				"position": Vector2(wall_x, pos.y + vel.y * time_to_wall),
				"new_velocity": Vector2(-vel.x * 0.8, vel.y)
			}
	if back_wall:
		var wall_y = back_wall.global_position.y + (20 if vel.y > 0 else -20)
		if abs(vel.y) > 0.1:
			var time_to_wall = (wall_y - pos.y) / vel.y
			if time_to_wall > 0 and time_to_wall < nearest_time:
				nearest_time = time_to_wall
				nearest_collision = {
					"time": time_to_wall,
					"position": Vector2(pos.x + vel.x * time_to_wall, wall_y),
					"new_velocity": Vector2(vel.x, -vel.y * 0.8)
				}
	
	return nearest_collision

func perform_sweeping():
	if !ball:
		_bailout_sweep("no ball")
		return
	frames_since_sweep_start += 1
	if frames_since_sweep_start % SWEEP_BAILOUT_CHECK_FREQUENCY == 0:
		if _should_bailout_sweep():
			_bailout_sweep("danger detected")
			return
	
	var goal_line_y = leftPost.y
	var goal_center = (leftPost + rightPost) / 2
	
	match sweep_state:
		"approaching":
			_handle_sweep_approach(goal_center, goal_line_y)
		"retreating":
			_handle_sweep_retreat(goal_center, goal_line_y)
		"bailed":
			_handle_sweep_bailout(goal_center, goal_line_y)

func _handle_sweep_approach(goal_center: Vector2, goal_line_y: float):
	# Check if we got the ball
	var distance_to_ball = global_position.distance_to(ball.global_position)
	if distance_to_ball < 30 or time_since_last_touch < 0.1:
		print("Got the ball! Retreating to goal")
		sweep_state = "retreating"
		return
	
	# Recalculate target periodically for moving ball
	if frames_since_sweep_start % 10 == 0:
		sweep_target = _calculate_sweep_intercept()
	
	# Avoid opponents while approaching
	var avoidance_vector = _calculate_sweep_avoidance()
	var target_with_avoidance = sweep_target + avoidance_vector
	
	# Path to ball
	var direction_to_target = (target_with_avoidance - global_position).normalized()
	navigation_agent.target_position = target_with_avoidance
	
	# Sprint to ball
	velocity = direction_to_target * get_buffed_attribute("sprint_speed")
	
	# Don't go past goal line while sweeping
	var buffer = 10.0
	if sign(goal_line_y) > 0:
		if global_position.y > goal_line_y - buffer:
			velocity.y = min(velocity.y, 0)  # Can't move further away from center
	else:
		if global_position.y < goal_line_y + buffer:
			velocity.y = max(velocity.y, 0)

func _handle_sweep_retreat(goal_center: Vector2, goal_line_y: float):
	# Return to defensive position after getting ball
	var defensive_position = Vector2(goal_center.x, goal_line_y - sign(goal_line_y) * 15)
	navigation_agent.target_position = defensive_position
	var distance_to_position = global_position.distance_to(defensive_position)
	
	# Sprint back
	var direction = (defensive_position - global_position).normalized()
	velocity = direction * get_buffed_attribute("sprint_speed")
	
	# Once we're back in position, return to defending
	if distance_to_position < 20:
		print("Back in position - returning to defending")
		sweep_state = "none"
		current_behavior = "defending"
		return
	
	# If ball gets loose again while retreating, might need to re-sweep
	if ball and global_position.distance_to(ball.global_position) > 100:
		var ball_threat = _calculate_ball_threat()
		if ball_threat > 0.6:  # Ball is threatening - stop retreating and defend
			sweep_state = "none"
			current_behavior = "defending"

func _handle_sweep_bailout(goal_center: Vector2, goal_line_y: float):
	# Emergency return to goal
	var safe_position = Vector2(goal_center.x, goal_line_y - sign(goal_line_y) * 10)
	navigation_agent.target_position = safe_position
	
	# Sprint back at maximum speed
	var direction = (safe_position - global_position).normalized()
	velocity = direction * get_buffed_attribute("sprint_speed")
	
	# Avoid opponents while bailing
	var avoidance = _calculate_sweep_avoidance()
	if avoidance.length() > 0:
		velocity += avoidance.normalized() * get_buffed_attribute("speed") * 0.5
		velocity = velocity.normalized() * get_buffed_attribute("sprint_speed")
	
	# Once safe, return to defending
	if global_position.distance_to(safe_position) < 25:
		print("Bailout complete - back to defending")
		sweep_state = "none"
		current_behavior = "defending"

# Calculate avoidance vector for opponents
func _calculate_sweep_avoidance() -> Vector2:
	var avoidance = Vector2.ZERO
	var opponents = [oppLF, oppRF]
	
	for opponent in opponents:
		if !opponent:
			continue
		
		var to_opponent = opponent.global_position - global_position
		var distance = to_opponent.length()
		
		# Avoid if opponent is close
		if distance < 100:
			var repulsion_strength = 1.0 - (distance / 100.0)  # Stronger when closer
			avoidance -= to_opponent.normalized() * repulsion_strength * 80.0
	
	return avoidance

# Decide if we should abort the sweep
func _should_bailout_sweep() -> bool:
	if sweep_state != "approaching":
		return false
	
	var closest_opponent = get_closest_opponent()
	if !closest_opponent:
		return false
	
	# Bailout condition 1: Opponent much closer to ball than us
	var our_dist_to_ball = global_position.distance_to(ball.global_position)
	var opp_dist_to_ball = closest_opponent.global_position.distance_to(ball.global_position)
	if opp_dist_to_ball < our_dist_to_ball * 0.6:
		print("Bailout: Opponent will reach ball first")
		return true
	
	# Bailout condition 2: Opponent dangerously close to us
	var opp_dist_to_keeper = global_position.distance_to(closest_opponent.global_position)
	if opp_dist_to_keeper < 50:
		print("Bailout: Opponent too close to keeper")
		return true
	
	# Bailout condition 3: Ball became more threatening to goal
	var ball_threat = _calculate_ball_threat()
	var distance_from_goal = global_position.distance_to(own_goal)
	if ball_threat > 0.7 and distance_from_goal > 60:
		print("Bailout: Ball became dangerous and we're too far out")
		return true
	
	# Bailout condition 4: Ball went past us toward goal
	var ball_past_keeper = false
	if sign(own_goal.y) > 0:  # Bottom goal
		ball_past_keeper = ball.global_position.y > global_position.y
	else:  # Top goal
		ball_past_keeper = ball.global_position.y < global_position.y
	
	if ball_past_keeper and ball.global_position.distance_to(own_goal) < global_position.distance_to(own_goal):
		print("Bailout: Ball went past us")
		return true
	
	# Bailout condition 5: We've been sweeping too long (safety)
	if frames_since_sweep_start > 180:  # 3 seconds at 60fps
		print("Bailout: Sweep timeout")
		return true
	
	# Bailout condition 6: Ball is going away from us now
	var ball_direction = ball_last_velocity.normalized()
	var to_ball = (ball.global_position - global_position).normalized()
	if ball_last_velocity.length() > 200 and ball_direction.dot(to_ball) < -0.3:
		print("Bailout: Ball moving away from us")
		return true
	
	# Personality factor: Less aggressive keepers bail more easily
	var aggression = get_buffed_attribute("aggression")
	if aggression < 60 and (opp_dist_to_ball < our_dist_to_ball * 0.8 or opp_dist_to_keeper < 80):
		print("Bailout: Low aggression keeper being cautious")
		return true
	
	return false

func _bailout_sweep(reason: String):
	print("Bailing from sweep: ", reason)
	sweep_state = "bailed"

func _path_clearness_to_ball(from_pos: Vector2, to_pos: Vector2) -> float:
	var clearness = 1.0
	var dir = (to_pos - from_pos).normalized()
	var dist = from_pos.distance_to(to_pos)
	var segments = int(dist / 40)
	for i in range(1, segments + 1):
		var check_pos = from_pos + dir * (i * 40)
		for opponent in [opposing_keeper, oppLF, oppRF]: #ignore the guards
			if !opponent:
				continue
			
			var opp_dist = opponent.global_position.distance_to(check_pos)
			if opp_dist < 80:
				clearness -= 0.3
			elif opp_dist < 120:
				clearness -= 0.15
		for opponent in [oppLF, oppRF]:
			if !opponent:
				continue
			var opponent_to_check = (check_pos - opponent.global_position).normalized()
			var opponent_velocity = opponent.velocity.normalized()
			if opponent_velocity.dot(opponent_to_check) > 0.7:
				clearness -= 0.2
	
	return clamp(clearness, 0.0, 1.0)

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
	return ball and global_position.distance_to(ball.global_position) < fencing_params["ball_proximity_threshold"] * (1.1 - get_buffed_attribute("reactions")/100.0)

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
	if _path_clearness(global_position, opp_goal) > (0.7 - (0.3 * get_buffed_attribute("aggression")/99.0)) or opposing_keeper.global_position.distance_to(opp_goal) > 250:
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
		if left_clear > (0.5 - (0.2 * get_buffed_attribute("aggression")/99.0)):
			options.append(buddyLF.global_position)
			weights.append(left_clear)
	if buddyRF:
		var right_clear = _path_clearness(ball.global_position, buddyRF.global_position)
		if right_clear > (0.5 - (0.2 * get_buffed_attribute("aggression")/99.0)):
			options.append(buddyRF.global_position)
			weights.append(right_clear)
	if buddyLG:
		var left_clear = _path_clearness(ball.global_position, buddyLG.global_position)
		if left_clear > (0.5 - (0.2 * get_buffed_attribute("aggression")/99.0)):
			if buddyLG.is_countering():
				left_clear *= 1.5 #make the easy pass
			options.append(buddyLF.global_position)
			weights.append(left_clear)
	if buddyRG:
		var right_clear = _path_clearness(ball.global_position, buddyRG.global_position)
		if right_clear > (0.5 - (0.2 * get_buffed_attribute("aggression")/99.0)):
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
	
	return [intercept, strike_dir * (800 + 200 * get_buffed_attribute("aggression")/99.0)]

#returns a float between 0 to 1 representing how open the ball's path is
func _path_clearness(from_pos: Vector2, to_pos: Vector2) -> float:
	var space = 1.0
	var dir = (to_pos - from_pos).normalized()
	var dist = from_pos.distance_to(to_pos)
	
	for i in range(1, int(dist / 50)):
		var check_pos = from_pos + dir * i * 50
		for opponent in [opposing_keeper, oppLF, oppRF]:
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
	var reaction_time = map_attribute_to_reaction_time(get_buffed_attribute("reactions"))
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
	var block_distance = (25*(get_buffed_attribute("blocking") - 50))/49 + 5 #maximum distance we'll block
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
	velocity = block_direction * get_buffed_attribute("sprint_speed") * human_block_speed_multiplier
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
	velocity = global_position.direction_to(intercept_point).normalized() * get_buffed_attribute("sprint_speed") * 2 #FAST AS FUCK BOI
	
func handle_super_blocking(delta: float):
	if not is_human_blocking or status.groove <= 0 or !is_machine:
		return false
	human_block_timer -= delta
	if human_block_timer <= 0:
		is_human_blocking = false
		return false
	human_block_target = ball.global_position + ball_last_velocity * 0.1
	var block_direction = global_position.direction_to(human_block_target).normalized()
	velocity = block_direction * get_buffed_attribute("sprint_speed") * 2.0
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
	velocity = block_direction * get_buffed_attribute("sprint_speed") * human_block_speed_multiplier
	return true # Return true to indicate we're still overriding input
			
func perform_blocking():
	#print("not in my house!")
	if !ball:
		current_behavior = "defending"
		return
	
	var goal_line_y = leftPost.y
	var goal_center = (leftPost + rightPost) / 2
	var style = get_defensive_style()
	
	# Recalculate intercept
	var intercept = _calculate_ball_intercept_with_bounces()
	
	# Validate intercept
	if intercept.distance_to(own_goal) > max_goal_offset * 2:
		current_behavior = "defending"
		return
	
	# Check if we're too far behind - switch to defending
	if ball.global_position.distance_to(own_goal) > global_position.distance_to(own_goal) + 50:
		current_behavior = "defending"
		return
	
	# Calculate target position based on personality
	var target_pos = intercept
	
	# Keepers who dive backwards adjust positioning
	if goalkeeping_preferences.dives_backwards:
		# Move target closer to goal line
		var backward_offset = style.backward_dive_offset
		target_pos.y = lerp(target_pos.y, goal_line_y, 0.4)
		
		# When diving, they'll dive backward from this position
		var dive_back_direction = (goal_center - global_position).normalized()
		target_pos += dive_back_direction * backward_offset
	
	# Clamp to goal line
	if sign(goal_line_y) > 0:
		target_pos.y = min(target_pos.y, goal_line_y - 1)
	else:
		target_pos.y = max(target_pos.y, goal_line_y + 1)
	
	# If ball very close, go directly for it
	if ball.global_position.distance_to(global_position) < 30:
		target_pos = ball.global_position
	
	navigation_agent.target_position = target_pos
	
	# Calculate dive speed based on blocking attribute
	var blocking_skill = get_buffed_attribute("blocking")
	var base_speed = get_buffed_attribute("sprint_speed")
	var dive_speed = base_speed * style.dive_speed_multiplier
	
	# Apply hesitation based on reactions
	if reaction_timer > 0:
		dive_speed *= 0.5  # Slower while hesitating
	
	var direction = (target_pos - global_position).normalized()
	velocity = direction * dive_speed * BLOCKING_BONUS

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

# Anticipation helper functions
func _check_for_potential_pass() -> void:
	if !ball or ball_last_velocity.length() < 100:
		anticipated_shooter = null
		return
	
	var ball_direction = ball_last_velocity.normalized()
	var ball_speed = ball_last_velocity.length()
	
	# Check each opponent forward
	var most_likely_shooter: Player = null
	var highest_threat: float = 0.0
	
	for opponent in [oppLF, oppRF]:
		if !opponent or opponent.is_stunned:
			continue
		
		# Calculate if opponent is in path of ball using distance_squared_to for performance
		var to_opponent = opponent.global_position - ball.global_position
		var distance_to_path = _distance_to_line_segment_squared(
			opponent.global_position,
			ball.global_position,
			ball.global_position + ball_direction * 500  # Look ahead 500 pixels
		)
		
		# Check if opponent is moving toward the ball path
		var opp_velocity_toward_ball = opponent.velocity.normalized().dot(to_opponent.normalized())
		var is_moving_to_intercept = opp_velocity_toward_ball > 0.3
		
		# Calculate threat level using squared distances for performance
		var proximity_to_path = 1.0 - clamp(sqrt(distance_to_path) / PASS_INTERCEPT_RANGE, 0.0, 1.0)
		var time_to_intercept = to_opponent.length() / max(ball_speed, 100.0)
		
		# Opponent closer to goal is more dangerous - use distance_squared_to for performance
		var dist_sq_to_goal = opponent.global_position.distance_squared_to(own_goal)
		var goal_proximity_threat = 1.0 - clamp(sqrt(dist_sq_to_goal) / 400.0, 0.0, 1.0)
		
		# Final threat calculation
		var threat = proximity_to_path * 0.4 + goal_proximity_threat * 0.4
		if is_moving_to_intercept:
			threat += 0.2
		
		# If opponent is likely to receive pass and is in scoring position
		if threat > 0.5 and threat > highest_threat:
			highest_threat = threat
			most_likely_shooter = opponent
	
	# Use positioning attribute to determine anticipation quality
	var positioning_skill = get_buffed_attribute("positioning")
	var anticipation_chance = positioning_skill / 99.0
	
	# Use reactions attribute to determine hesitation frames
	var reactions_skill = get_buffed_attribute("reactions")
	var base_hesitation_frames = DIVE_HESITATION_FRAMES
	# Higher reactions = fewer hesitation frames (faster anticipation)
	var hesitation_frames = int(base_hesitation_frames * (1.0 - reactions_skill / 99.0))
	hesitation_frames = max(hesitation_frames, 1)  # At least 1 frame
	
	# Add some randomness based on positioning skill
	if most_likely_shooter and highest_threat > 0.6:
		# Higher positioning = more accurate anticipation
		if randf() < anticipation_chance:
			anticipated_shooter = most_likely_shooter
			anticipation_frames = hesitation_frames
			last_anticipated_position = anticipated_shooter.global_position
			return
	
	anticipated_shooter = null
	anticipation_frames = 0

# Helper function to calculate squared distance from point to line segment (more efficient)
func _distance_to_line_segment_squared(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec = line_end - line_start
	var line_length_sq = line_vec.length_squared()
	if line_length_sq == 0:
		return point.distance_squared_to(line_start)
	
	var t = clamp((point - line_start).dot(line_vec) / line_length_sq, 0.0, 1.0)
	var projection = line_start + t * line_vec
	return point.distance_squared_to(projection)

func _calculate_anticipation_position(shooter: Player) -> Vector2:
	if !shooter:
		return Vector2.ZERO
	
	var goal_center = (leftPost + rightPost) / 2
	var goal_line_y = leftPost.y
	
	# Calculate line from shooter to goal center
	var shooter_pos = shooter.global_position
	var to_goal = goal_center - shooter_pos
	
	# Position ourselves along this line based on positioning skill
	var positioning_skill = get_buffed_attribute("positioning")
	
	# Perfect positioning (99) = directly on the line between shooter and goal
	# Poor positioning (0) = just follows ball
	var position_quality = positioning_skill / 99.0
	
	# Calculate where to stand on the line
	# Higher skill = closer to optimal cutoff angle
	var cutoff_distance = lerp(30.0, 80.0, position_quality)  # How far out from goal
	
	# Don't go too far from goal line
	var max_distance_from_line = 40.0
	var adjusted_distance = min(cutoff_distance, shooter_pos.distance_to(goal_center) * 0.5)
	adjusted_distance = clamp(adjusted_distance, 10.0, max_distance_from_line)
	
	# Calculate position along the line
	var direction_to_goal = to_goal.normalized()
	var anticipation_pos = goal_center - direction_to_goal * adjusted_distance
	
	# Adjust Y position to stay in front of goal line
	if sign(goal_line_y) > 0:  # Bottom goal
		anticipation_pos.y = min(anticipation_pos.y, goal_line_y - 5)
	else:  # Top goal
		anticipation_pos.y = max(anticipation_pos.y, goal_line_y + 5)
	
	# Add some error based on positioning skill (less error for higher skill)
	var error_margin = (100 - positioning_skill) * 0.3
	anticipation_pos.x += randf_range(-error_margin, error_margin)
	anticipation_pos.y += randf_range(-error_margin * 0.5, error_margin * 0.5)
	
	return anticipation_pos

func defending_behavior(delta: float):
	if !ball:
		return
	
	var goal_center: Vector2 = (leftPost + rightPost) / 2
	var goal_width: float = rightPost.distance_to(leftPost)
	var style = get_defensive_style()
	var goal_line_y = leftPost.y
	
	# Check for potential passes to opponents
	_check_for_potential_pass()
	
	# Update anticipation frames
	if anticipation_frames > 0:
		anticipation_frames -= 1
	
	# Get back to goal if too far
	if global_position.distance_to(goal_center) > 80:
		navigation_agent.target_position = goal_center
		var speed = get_buffed_attribute("speed")
		if status.boost > 0:
			is_sprinting = true
			speed = get_buffed_attribute("sprint_speed")
		velocity = global_position.direction_to(goal_center).normalized() * speed
		return
	
	# Check reaction delay for direction changes
	if _check_reaction_delay(delta):
		return
	
	var challenge_depth = style.challenge_distance
	
	# Calculate base position based on ball
	var ball_field_ratio = clamp(ball.global_position.x / 100.0, -1.0, 1.0)
	var base_ideal_x = goal_center.x + ball_field_ratio * (goal_width * 0.4)
	
	# Calculate ideal Y position based on ball distance
	var ball_distance_to_goal_y = abs(ball.global_position.y - leftPost.y)
	var dynamic_depth = min(ball_distance_to_goal_y * 0.3, challenge_depth)
	
	# Adjust for goalkeeper preferences
	if goalkeeping_preferences.dives_backwards:
		dynamic_depth *= 0.6
	
	var base_ideal_y = goal_line_y - sign(goal_line_y) * dynamic_depth
	
	# Start with base position
	var ideal_position = Vector2(base_ideal_x, base_ideal_y)
	
	# Apply anticipation if we have a likely shooter
	if anticipated_shooter and anticipation_frames > 0:
		var anticipation_pos = _calculate_anticipation_position(anticipated_shooter)
		
		var ball_to_shooter = (anticipated_shooter.global_position - ball.global_position).normalized()
		var ball_direction = ball_last_velocity.normalized()
		var pass_alignment = ball_direction.dot(ball_to_shooter)
		
		# Calculate blend factor
		var positioning_skill = get_buffed_attribute("positioning")
		var dist_sq_to_goal = anticipated_shooter.global_position.distance_squared_to(own_goal)
		var danger_factor = 1.0 - clamp(sqrt(dist_sq_to_goal) / 300.0, 0.0, 1.0)
		
		var blend_factor = clamp(pass_alignment * 0.5 + (positioning_skill / 99.0) * 0.3 + danger_factor * 0.2, 0.0, 1.0)
		
		# Blend positions
		ideal_position = ideal_position.lerp(anticipation_pos, blend_factor)
		
		# Visual feedback (optional)
		if debug:
			print("Anticipating pass to: ", anticipated_shooter.name, " Blend: ", blend_factor, " Frames left: ", anticipation_frames)
	
	# Non-contact keepers adjust position based on guards
	if !goalkeeping_preferences.likes_contact:
		ideal_position.x = _adjust_position_for_guard_protection(ideal_position.x, goal_center)
	
	# Apply positioning skill variance
	var positioning_skill = get_buffed_attribute("positioning")
	var variance = (100 - positioning_skill) / 6.0 #0-8
	ideal_position.x += randf_range(-variance, variance)
	ideal_position.x = clamp(ideal_position.x, goal_center.x - max_goal_offset, goal_center.x + max_goal_offset)
	if sign(goal_line_y) > 0:
		ideal_position.y = min(ideal_position.y, goal_line_y - 1)
	else:
		ideal_position.y = max(ideal_position.y, goal_line_y + 1)
	navigation_agent.target_position = ideal_position
	var distance = global_position.distance_to(navigation_agent.target_position)
	var ball_threat = _calculate_ball_threat()
	if anticipated_shooter and anticipation_frames > 0:
		is_sprinting = true
		velocity = (navigation_agent.target_position - global_position).normalized() * get_buffed_attribute("sprint_speed")
	elif distance > 20 and (ball_threat > 0.5 or status.boost > 0):
		is_sprinting = true
		velocity = (navigation_agent.target_position - global_position).normalized() * get_buffed_attribute("sprint_speed")
	else:
		velocity = (navigation_agent.target_position - global_position).normalized() * get_buffed_attribute("speed")
	
	check_ball_close()

func _on_ball_touched_by_player(player: Player):
	if player.team == team:#our team touched it
		anticipated_shooter = null
		anticipation_frames = 0
		forced_guess = ""
		return
	elif player == oppLF or player == oppRF:
		if player == anticipated_shooter:
			var reactions_skill = get_buffed_attribute("reactions")
			var hesitation_frames = int(DIVE_HESITATION_FRAMES * (1.0 - reactions_skill / 99.0))
			hesitation_frames = max(hesitation_frames, 1)
			var dist_sq_to_goal = player.global_position.distance_squared_to(own_goal)
			
			if dist_sq_to_goal < 400: #20 units, too close to the goal to react
				current_behavior = "holding"
				hold_frame = hesitation_frames
				
				# Use weighted decision based on shot history
				var weights = set_reaction_save_weights(player)
				var actions = ["dive_left", "dive_right", "stay_middle", "charge_out", "regular_block"]
				var chosen_action = weighted_random_choice(actions, weights)
				
				match chosen_action:
					"dive_left":
						forced_guess = "left"
					"dive_right":
						forced_guess = "right"
					"stay_middle":
						forced_guess = "middle"
					"charge_out":
						forced_guess = "middle"  # Charge out is a special middle action
					"regular_block":
						forced_guess = ""  # No guess, use regular blocking
						current_behavior = "blocking"
						return
			else: #far enough to react properly
				var reaction_time = map_attribute_to_reaction_time(reactions_skill)
				await get_tree().create_timer(reaction_time).timeout
				current_behavior = "blocking"
		anticipated_shooter = null
		anticipation_frames = 0

func perform_holding(frame: int):
	if !ball: 
		current_behavior = "defending"
		return
	
	check_ball_close()
	
	if frame > 0:
		hold_frame = hold_frame - 1
		if global_position.distance_to(navigation_agent.target_position) < 3.0:
			current_behavior = "holding"
			velocity = Vector2.ZERO
		if global_position.distance_to(ball.global_position) < sqrt(get_buffed_attribute("reactions")) - get_buffed_attribute("reactions")/10:
			current_behavior = "defending"
			return
	else:
		if forced_guess != "":
			current_behavior = "guessing"
			has_guessed = false
		else:
			current_behavior = "defending"

func _project_ball_path_with_reflections() -> Vector2:
	if !ball or ball_last_velocity.length() < 40: #ball is moving too slow to make a projection
		return Vector2.ZERO
	
	var current_pos = ball.global_position
	var current_vel = ball_last_velocity
	var goal_line_y = leftPost.y
	var max_bounces = 3
	var bounce_count = 0
	var deflection_risk = _calculate_deflection_risk(current_pos, current_vel)
	if deflection_risk > 0.7:
		return Vector2(current_pos.x * 0.7, goal_line_y)
	
	while bounce_count < max_bounces:
		if abs(current_vel.y) < 0.1:
			break
		var time_to_goal = (goal_line_y - current_pos.y) / current_vel.y
		if time_to_goal < 0: #ball going away from the goal
			break
		var projected_x = current_pos.x + current_vel.x * time_to_goal
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
	
	
#have to guess to make some saves
func perform_guessing():
	if has_guessed:
		return
	if forced_guess != "":
		last_guess = forced_guess
		has_guessed = true
		if forced_guess == "left":
			dive_left()
		elif forced_guess == "right":
			dive_right()
		else: # middle
			if goalkeeping_preferences.charges_out:
				charge_middle()
			else:
				current_behavior = "defending"
		forced_guess = ""
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
	var style = get_defensive_style()
	
	current_behavior = "holding"
	# Use reactions attribute to determine hesitation frames
	var reactions_skill = get_buffed_attribute("reactions")
	var hesitation_frames = int(style.dive_hesitation * (1.0 - reactions_skill / 99.0))
	hesitation_frames = max(hesitation_frames, 1)  # At least 1 frame
	hold_frame = hesitation_frames
	
	var target_x = leftPost.x
	var target_y = global_position.y
	
	# Backward divers go toward goal
	if goalkeeping_preferences.dives_backwards:
		var goal_line_y = leftPost.y
		target_y = lerp(global_position.y, goal_line_y, 0.6)
		target_x = lerp(global_position.x, leftPost.x, 0.75)  # 3/4 of the way
	else:
		target_x = (leftPost.x * 3 + global_position.x) / 4
	
	var place = Vector2(target_x, target_y)
	navigation_agent.target_position = place
	
	var dir = global_position.direction_to(place)
	var dive_speed = get_buffed_attribute("sprint_speed") * style.dive_speed_multiplier
	velocity = dir * dive_speed
	move_and_slide()

func dive_right():
	check_ball_close()
	var style = get_defensive_style()
	
	current_behavior = "holding"
	# Use reactions attribute to determine hesitation frames
	var reactions_skill = get_buffed_attribute("reactions")
	var hesitation_frames = int(style.dive_hesitation * (1.0 - reactions_skill / 99.0))
	hesitation_frames = max(hesitation_frames, 1)  # At least 1 frame
	hold_frame = hesitation_frames
	
	var target_x = rightPost.x
	var target_y = global_position.y
	
	# Backward divers go toward goal
	if goalkeeping_preferences.dives_backwards:
		var goal_line_y = rightPost.y
		target_y = lerp(global_position.y, goal_line_y, 0.6)
		target_x = lerp(global_position.x, rightPost.x, 0.75)
	else:
		target_x = (rightPost.x * 3 + global_position.x) / 4
	
	var place = Vector2(target_x, target_y)
	navigation_agent.target_position = place
	
	var dir = global_position.direction_to(place)
	var dive_speed = get_buffed_attribute("sprint_speed") * style.dive_speed_multiplier
	velocity = dir * dive_speed
	move_and_slide()

func charge_middle():
	if !goalkeeping_preferences.charges_out:
		current_behavior = "defending"
		return
	
	check_ball_close()
	var style = get_defensive_style()
	
	current_behavior = "holding"
	# Use reactions attribute to determine hesitation frames
	var reactions_skill = get_buffed_attribute("reactions")
	var hesitation_frames = int(style.dive_hesitation * 1.3 * (1.0 - reactions_skill / 99.0))
	hesitation_frames = max(hesitation_frames, 1)  # At least 1 frame
	hold_frame = hesitation_frames
	
	# Charge forward aggressively
	var charge_distance = lerp(30.0, 60.0, get_buffed_attribute("aggression") / 99.0)
	var target_y = global_position.y - sign(global_position.y) * charge_distance
	var place = Vector2(global_position.x, target_y)
	
	navigation_agent.target_position = place
	
	var dir = global_position.direction_to(place)
	var dive_speed = get_buffed_attribute("sprint_speed") * style.dive_speed_multiplier
	velocity = dir * dive_speed
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
		"workhorse":
			is_workhorse = true
	if status.groove <= 0:
		deactivate_special()
			
func is_special_active():
	if is_maestro:
		return true
	elif is_machine:
		return true
	elif is_spin_doctor:
		return true
	elif is_workhorse:
		return true
	else:
		return false

func use_special_ability():
	if is_maestro: #maestro chews through groove fastest
		status.groove = status.groove - 0.18
	elif is_machine or is_workhorse:
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
	is_workhorse = false
		
func ai_check_special_ability():
	if status.groove >= get_buffed_attribute("confidence") / 2:
		var activate_chance = status.groove / get_buffed_attribute("confidence")
		if randf() < activate_chance or desperate == true:
			print("AI using special ability")
			activate_special_ability()

		
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
	if ball.global_position.distance_to(own_goal) < max_goal_offset or ball.global_position.distance_to(global_position) < sqrt(get_buffed_attribute("reactions")):
		current_behavior = "blocking"
		perform_blocking()
		return true
	else:
		return false
		
#if we're close enough to the ball and have no input, help the player out a little bit
func human_check_ball_close():
	if !ball: return
	if ball.global_position.distance_to(global_position) < sqrt(get_buffed_attribute("reactions")):
		if !is_stunned and !is_dodging and velocity == Vector2(0,0):
			if is_machine:
				super_block(ball.global_position, ball.global_position)
			else:
				human_assisted_block(ball.global_position, ball.global_position)
				
func perform_pitch_defense():
	if !ball:
		current_behavior = "defending"
		return
	
	if ball.current_state != ball.BallState.PITCHING and ball.current_state != ball.BallState.SPECIAL_PITCH:
		current_behavior = "defending"
		return
	
	var blocking_skill = get_buffed_attribute("blocking")
	var prediction_quality = blocking_skill / 99.0
	var style = get_defensive_style()
	
	# Calculate predicted position
	var predicted_pos
	if ball.current_state == ball.BallState.PITCHING:
		predicted_pos = predict_normal_pitch_path(prediction_quality)
	else:
		predicted_pos = predict_special_pitch_path(prediction_quality)
	
	# Add error based on blocking skill
	var error_range = (100 - blocking_skill) * 0.5
	predicted_pos.x += randf_range(-error_range, error_range)
	
	# Keepers who dive backwards need different positioning
	if goalkeeping_preferences.dives_backwards:
		# Stay deeper to have room to dive back
		var goal_line_y = leftPost.y
		predicted_pos.y = lerp(predicted_pos.y, goal_line_y, 0.4)
	
	# Keepers who charge out move up for pitches
	if goalkeeping_preferences.charges_out:
		var goal_center = (leftPost + rightPost) / 2
		var charge_distance = lerp(20.0, 50.0, get_buffed_attribute("aggression") / 99.0)
		predicted_pos.y = goal_center.y + sign(predicted_pos.y - goal_center.y) * charge_distance
	
	# Clamp to goal boundaries
	var goal_center = (leftPost + rightPost) / 2
	predicted_pos.x = clamp(predicted_pos.x, goal_center.x - max_goal_offset, goal_center.x + max_goal_offset)
	
	# Apply reaction hesitation
	if reaction_timer > 0:
		reaction_timer -= get_physics_process_delta_time()
		velocity = velocity * 0.5
		return
	
	navigation_agent.target_position = predicted_pos
	
	# Movement speed
	var base_speed = get_buffed_attribute("sprint_speed")
	var move_speed = base_speed * style.dive_speed_multiplier * BLOCKING_BONUS
	
	velocity = (predicted_pos - global_position).normalized() * move_speed

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

func get_defensive_style() -> Dictionary:
	var aggression = get_buffed_attribute("aggression")
	var reactions = get_buffed_attribute("reactions")
	var blocking = get_buffed_attribute("blocking")
	
	# Challenge depth from preferences
	var depth = goalkeeping_preferences.challenge_depth
	
	# Sweeper keepers play further out
	if goalkeeping_preferences.sweeper_keeper:
		depth += 15.0
	
	# Likes contact keepers are more aggressive in positioning
	if goalkeeping_preferences.likes_contact:
		depth += lerp(5.0, 20.0, aggression / 99.0)
	
	return {
		"challenge_distance": depth,
		"sweep_willingness": aggression if goalkeeping_preferences.sweeper_keeper else 0.0,
		"dive_speed_multiplier": lerp(1.0, 2.2, float(blocking) / 99.0),
		"dive_hesitation": lerp(float(DIVE_HESITATION_FRAMES), float(DIVE_HESITATION_FRAMES) * 0.3, reactions / 99.0),  # Cast to float
		"backward_dive_offset": 25.0 if goalkeeping_preferences.dives_backwards else 0.0,
		"contact_aggression": aggression / 99.0 if goalkeeping_preferences.likes_contact else 0.0
	}


func _decide_attack_opponent() -> bool:
	if !goalkeeping_preferences.likes_contact:
		return false
	
	var closest_opponent = get_closest_opponent()
	if !closest_opponent:
		return false
	
	var opp_distance = global_position.distance_to(closest_opponent.global_position)
	var ball_distance = global_position.distance_to(ball.global_position)
	
	# Don't attack if we're too far away
	if opp_distance > CONTACT_EVALUATION_DISTANCE:
		return false
	
	# Check 1: Is opponent closer than ball? (Attacking makes sense)
	var opponent_closer = opp_distance < ball_distance * 0.8
	
	# Check 2: Would attacking take us away from dangerous ball position?
	var ball_threat = _calculate_ball_threat()
	var safe_to_leave_goal = ball_threat < 0.4
	
	# Check 3: Power comparison (don't attack much stronger opponents)
	var power_ratio = get_buffed_attribute("power") / closest_opponent.get_buffed_attribute("power")
	var reasonable_matchup = power_ratio > 0.6
	
	# Check 4: Is opponent actually threatening? (moving toward us or has ball)
	var opponent_velocity_toward_us = closest_opponent.velocity.normalized().dot(
		(global_position - closest_opponent.global_position).normalized()
	)
	var opponent_threatening = opponent_velocity_toward_us > 0.3 or closest_opponent.has_ball
	
	# All conditions must be favorable
	if opponent_closer and safe_to_leave_goal and reasonable_matchup and opponent_threatening:
		# Final decision based on aggression
		var attack_chance = get_buffed_attribute("aggression") / 99.0
		return randf() < attack_chance
	
	return false

#try to find a position where our guards are protecting us
func _adjust_position_for_guard_protection(ideal_x: float, goal_center: Vector2) -> float:
	var guard_positions = []
	if buddyLG:
		guard_positions.append(buddyLG.global_position)
	if buddyRG:
		guard_positions.append(buddyRG.global_position)
	
	if guard_positions.is_empty():
		return ideal_x
	
	var leftmost_guard = INF
	var rightmost_guard = -INF
	
	for pos in guard_positions:
		leftmost_guard = min(leftmost_guard, pos.x)
		rightmost_guard = max(rightmost_guard, pos.x)
	
	var protected_x = clamp(ideal_x, leftmost_guard, rightmost_guard)
	
	return lerp(ideal_x, protected_x, GUARD_PROTECTION_WEIGHT)
	
func _check_reaction_delay(delta: float) -> bool:
	var current_ball_direction = ball_last_velocity.normalized()
	if last_ball_direction != Vector2.ZERO:
		var direction_change = last_ball_direction.angle_to(current_ball_direction)
		if abs(direction_change) > deg_to_rad(45):
			if !reacting:
				reacting = true
				reaction_timer = map_attribute_to_reaction_time(get_buffed_attribute("reactions"))
			
			if reaction_timer > 0:
				reaction_timer -= delta
				velocity = Vector2.ZERO
				return true
			else:
				reacting = false
	
	last_ball_direction = current_ball_direction
	return false

func _calculate_ball_threat() -> float: #how dangerous is the ball to our goal right now?
	var dist_to_goal = ball.global_position.distance_to(own_goal)
	var speed = ball_last_velocity.length()
	var direction_to_goal = (own_goal - ball.global_position).normalized()
	var ball_direction = ball_last_velocity.normalized()
	
	var direction_threat = max(0.0, ball_direction.dot(direction_to_goal))
	var speed_threat = clamp(speed / 1000.0, 0.0, 1.0)
	var distance_threat = 1.0 - clamp(dist_to_goal / 500.0, 0.0, 1.0)
	
	return (direction_threat * 0.5 + speed_threat * 0.3 + distance_threat * 0.2)

func set_reaction_save_weights(forward: Player) -> Array:
	var weights = {
		"dive_left": 0.0,
		"dive_right": 0.0,
		"stay_middle": 0.0,
		"charge_out": 0.0,
		"regular_block": 0.0
	}
	
	var shot_history = []
	var total_shots = 0
	var left_shots = 0
	var right_shots = 0
	var middle_shots = 0
	if forward == oppLF:
		shot_history = lf_shot_history
	elif forward == oppRF:
		shot_history = rf_shot_history
	weights["dive_left"] = 0.2
	weights["dive_right"] = 0.2
	if goalkeeping_preferences.charges_out:
		weights["charge_out"] = 0.5
		weights["regular_block"] = 0.1
	else:
		weights["stay_middle"] = 0.3
		weights["regular_block"] = 0.3
	
	return [weights["dive_left"], weights["dive_right"], weights["stay_middle"], 
			weights["charge_out"], weights["regular_block"]]
	total_shots = shot_history.size()
	left_shots = shot_history.count("left")
	right_shots = shot_history.count("right")
	middle_shots = shot_history.count("middle")
	if total_shots > 0:
		weights["dive_left"] += float(left_shots) / total_shots
		weights["dive_right"] += float(right_shots) / total_shots
		if goalkeeping_preferences.charges_out:
			weights["charge_out"] += float(middle_shots) / total_shots
		else:
			weights["stay_middle"] += float(middle_shots) / total_shots
	else:
		weights["dive_left"] = guess_preferences.left
		weights["dive_right"] = guess_preferences.right
		weights["stay_middle"] = guess_preferences.middle
	if goalkeeping_preferences.charges_out:
		weights["stay_middle"] = 0
	else:
		weights["charge_out"] = 0
	weights["regular_block"] += 0.2
	var total_weight = weights["dive_left"] + weights["dive_right"] + \
					  weights["stay_middle"] + weights["charge_out"] + \
					  weights["regular_block"]
	if total_weight > 0:
		weights["dive_left"] /= total_weight
		weights["dive_right"] /= total_weight
		weights["stay_middle"] /= total_weight
		weights["charge_out"] /= total_weight
		weights["regular_block"] /= total_weight
	return [weights["dive_left"], weights["dive_right"], weights["stay_middle"], 
			weights["charge_out"], weights["regular_block"]]

#stores shotes as "left", "right", or "middle"
func record_shot(forward: Player, shot_direction: String):
	if forward == oppLF:
		lf_shot_history.append(shot_direction)
		if lf_shot_history.size() > 30:
			lf_shot_history.pop_front()
	elif forward == oppRF:
		rf_shot_history.append(shot_direction)
		if rf_shot_history.size() > 30:
			rf_shot_history.pop_front()

#if the opponent substitutes their forwards, we have to re-set the history
func reset_shooter(left_side: bool):
	if left_side:
		lf_shot_history = []
	else:
		rf_shot_history = []
