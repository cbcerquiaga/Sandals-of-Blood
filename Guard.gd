extends Player
class_name Guard

var strategy = {
	"aggression": 0.6,  # 0-1, determines attack tendency
	"anticipation": 0.5,  # 0-1, predicts forward movement
	"marking": 0.7,  # 0-1, likelihood to stay with mark (replaces discipline)
	"fluidity": 0.6,  # 0-1, preference to switch forwards on a pick, preference to fill in for keeper
	"zone": true,  # true or false, whether to play zone or man
	"lg_trap": false, #in a zone, if the LG will trap. if false, RG plays gk
	"rg_trap": true,#in a zone, if the RG will trap. if false, RG plays gk
	"chasing": 0.1,  # 0-inf, likelihood to chase loose balls
	"goal_defense_threshold": 35,  # Distance at which keeper is considered out of position
	"escort_distance": 10#how closely an escorting guard will follow the keeper
}

# Mark tracking
var defending_goal_position: Vector2
var leftPost: Vector2
var rightPost: Vector2
var buddy_keeper: Keeper = null
var buddy_guard
var assigned_forward: Forward = null
var other_forward: Forward = null
var forward_last_intent: String = ""
var forward_last_position: Vector2
var forward_last_velocity: Vector2
var mark_incapacitated: bool = false
var should_play_zone: bool = false
var is_lead_guard: bool = false #who decides whether or not to play zone
var predicted_ball_path: Array = []
var current_intercept_point: Vector2 = Vector2.ZERO
var rebound_projection_accuracy: float = 1.0
var ball_last_sighted: Vector2
var ball_direction_projection: Vector2
const MAX_REACTION_TIME: float = 0.5  # seconds
const MIN_REACTION_TIME: float = 0.1  # seconds
const BLOCKING_BONUS: float = 1.5 #bonus speed when blocking
const max_goal_offset: float = 29.5
var last_behavior: String

#aiming
var opp_keeper: Keeper = null
var aim_point: Vector2
var aim_selection
var oppGoal: Vector2

# Navigation
var current_target: Vector2
var engagement_decision: String = ""
var path_update_timer: float = 0


# Nodes
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var intent_timer: Timer = $DecisionTimer

func _ready():
	z_index = 2
	behaviors = ["chasing", "marking", "pressing", "helping", "doubling", "intercepting", "fencing", "returning", "goalkeeping", "trapping", "escorting", "hunting"]
	current_behavior = "marking"
	super._ready()
	position_type = "guard"
	oppGoal = Vector2(defending_goal_position.x, 0 - defending_goal_position.y)

func assign_forward(forward: Forward):
	assigned_forward = forward
	mark_incapacitated = false

func _physics_process(delta):
	super._physics_process(delta)
	should_play_zone = strategy.zone
	if not is_controlling_player and can_move:
		check_ball_attacking_half()
		update_ai_movement(delta)
		update_forward_tracking(delta)
		clamp_target_position()
		

func update_forward_tracking(delta):
	if not assigned_forward:
		return
	
	# Track forward's movement patterns
	forward_last_velocity = (assigned_forward.global_position - forward_last_position) / delta
	forward_last_position = assigned_forward.global_position
	
	# Check if mark is incapacitated
	if not mark_incapacitated and assigned_forward.check_is_incapacitated():
		mark_incapacitated = true
		_on_mark_incapacitated()

func update_ai_movement(delta):
	if not assigned_forward:
		return
	
	path_update_timer -= delta
	if path_update_timer <= 0:
		update_behavior()
		path_update_timer = 0.3 # Update path 3 times per second
	else:
		perform_ai()
		clamp_target_position()
	
	var next_path_pos = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	velocity = direction * attributes.speed
	move_and_slide()

func update_behavior():
	if !assigned_forward or !other_forward or !ball or !buddy_keeper:
		print("Missing somebody. F1: ", assigned_forward, ", F2: ", other_forward, ", Ball: ", ball, "buddy: ", buddy_keeper)
		return
	
	if should_play_zone:
		handle_zone_defense_behavior()
	else:
		handle_man_defense_behavior()
	
	navigation_agent.target_position = current_target

#in zone defense, one player will take over the goal and the other will usually trap midfield, but may go rogue
func handle_zone_defense_behavior():
	if should_play_escort():
		current_behavior = "escorting"
		#buddy_guard.current_behavior = "trapping" #shouldn't have to do this
	elif should_trap():
		if ball.global_position.distance_to(global_position) < attributes.aggression * strategy.chasing:
			current_behavior = "chasing"
		else:
			current_behavior = "trapping"
	#if team == 1 and plays_left_side:
		#print("I am the LG and I am ", current_behavior)
	#elif team == 1 and !plays_left_side:
		#print("I am the RG and I am ", current_behavior, " and I'm on team: ", team)

#regular defensive behavior. LG covers RF, RG covers LF, but they may help each other, switch, or go after the ball
func handle_man_defense_behavior():
	if buddy_keeper.is_stunned or buddy_keeper.global_position.distance_to(defending_goal_position) > strategy.goal_defense_threshold and current_behavior != "goalkeeping" and buddy_guard.current_behavior != "goalkeeping" and global_position.distance_to(defending_goal_position) < buddy_guard.global_position.distance_to(defending_goal_position):
		if randf() < strategy.fluidity or (buddy_keeper.global_position.distance_to(defending_goal_position) > strategy.goal_defense_threshold * 2 and randf() < strategy.fluidity * 2) or buddy_keeper.stun_timer.time_left > strategy.marking:
			current_behavior = "goalkeeping"
			handle_goalkeeping_movement()
	elif buddy_guard.current_behavior == "goalkeeping":
		if global_position.distance_to(ball.global_position) < 20:
			current_behavior = "chasing"
		else:
			current_behavior = "helping"
	elif mark_incapacitated or assigned_forward.global_position.distance_to(defending_goal_position) > 65 and global_position.distance_to(ball.global_position) < 90:
		current_behavior = "chasing"
		current_target = ball.global_position
	else:
		var read = randi_range(0,100)
		if read < attributes.positioning: #we get to know the opposing forward's behavior if our guy makes a good read
			var choose = randi_range(0, 100)
			if assigned_forward.current_behavior == "bull_rush" or assigned_forward.current_behavior == "speed_rush":
				if choose < attributes.aggression:
					current_behavior = "pressing"
					pressure_defense()
				else:
					current_behavior = "marking"
					cover_defense()
			elif assigned_forward.current_behavior == "pick" or other_forward.current_behavior == "pick" and randf() < strategy.fluidity:
				switch_forward()
			elif assigned_forward.current_behavior == "target_man"  and other_forward.current_behavior == "shooter":
				current_behavior = "intercepting"
				
			elif should_help():
				current_behavior = "helping"
				handle_help_defense()
			elif assigned_forward.current_behavior == "cower":
				current_behavior = "doubling"
				handle_double_team_defense()
			elif assigned_forward.current_behavior == "rebound":
				if choose < attributes.aggression:
					current_behavior = "pressing"
					pressure_defense()
				else: #better get to that ball first
					current_behavior = "chasing"
					chase_ball()
				
		else:
			current_behavior = "marking"
			cover_defense()

func should_play_escort() -> bool:
	#print("should I play escort? ", plays_left_side, " and L:", strategy.lg_trap, " and R:", strategy.rg_trap)
	# Check if we should play goalkeeper in zone defense
	if plays_left_side and !strategy.lg_trap:
		return true
	elif !plays_left_side and !strategy.rg_trap:
		return true
	else:
		return false

func should_trap() -> bool:
	if plays_left_side and strategy.lg_trap:
		return true
	if !plays_left_side and strategy.rg_trap:
		return true
	return false

func perform_ai():
	match current_behavior:
		"marking":
			cover_defense()
		"helping":
			handle_help_defense()
		"pressing":
			pressure_defense()
		"chasing":
			chase_ball()
		"doubling":
			handle_double_team_defense()
		"intercepting":
			handle_intercept_movement()
		"goalkeeping":
			handle_goalkeeping_movement()
		"trapping":
			handle_trapping()
		"blocking":
			perform_blocking()
		"escorting":
			perform_escorting()
		"fencing":
			perform_fencing()
		"hunting":
			perform_hunting()

func pressure_defense():
	if global_position.distance_to(assigned_forward.global_position) > attributes.aggression - 25:
		navigation_agent.target_position = assigned_forward.global_position
	else:
		attempt_attack(assigned_forward.global_position)
	
func handle_help_defense():
	if !assigned_forward or !other_forward or !ball:
		return
	var centerPos = (assigned_forward.global_position + other_forward.global_position)/2
	var helpPos = (centerPos + defending_goal_position)/2
	var rand = randi_range(0,100)
	if rand > attributes.positioning:
		var diff = rand - attributes.positioning
		if diff > 10:
			diff = 10
		helpPos = helpPos + Vector2(randf_range(0 - diff, diff), randf_range(0 - diff, diff))
	var cheat_direction
	if assigned_forward.global_position.distance_squared_to(ball.global_position) <= other_forward.global_position.distance_squared_to(ball.global_position):
		cheat_direction = (assigned_forward.global_position - global_position).normalized()
	else:
		cheat_direction = (other_forward.global_position - global_position).normalized()
	helpPos = helpPos + cheat_direction * (attributes.aggression / 10)
	navigation_agent.target_position = helpPos
	
#get between man and goal. Cheat to the middle a bit to push the forward away when it comes
func cover_defense():
	if !assigned_forward:
		return
	var default_position = (assigned_forward.global_position + defending_goal_position)/2
	#if the forward's position isn't too threatening yet, cheat to the middle
	if assigned_forward.global_position.distance_to(global_position) > attributes.aggression/2 and assigned_forward.global_position.distance_squared_to(global_position) > global_position.distance_squared_to(defending_goal_position):
		var rand = randi_range(0,100)
		if rand < attributes.positioning:
			default_position.x = default_position.x * 5/6 #cheat to the middle a bit #TODO balance
		elif rand - attributes.positioning > 10: #bad positioning roll
			default_position.x = default_position.x * 3/4 #too much cheat #TODO balance
		else: #close positioning roll
			default_position.x = default_position.x * 7/8 #less than ideal cheating #TODO balance
	else:
		current_behavior = "pressing"
	pass


func handle_intercept_movement():
	var middle = (assigned_forward.global_position + other_forward.global_position)/2
	var half_assigned = (assigned_forward.global_position + middle)/2
	var half_other = (assigned_forward.global_position + middle)/2
	var middle_dist = global_position.distance_squared_to(middle)
	var ass_dist = global_position.distance_squared_to(half_assigned)
	var oth_dist = global_position.distance_squared_to(half_other)
	if ass_dist < oth_dist and ass_dist < middle_dist:
		navigation_agent.target_position = half_assigned
	elif oth_dist < ass_dist and oth_dist < middle_dist:
		navigation_agent.target_position = half_other
	else:
		navigation_agent.target_position = middle

func attempt_dodge():
	super.attempt_dodge()

func switch_forward():
	var temp = other_forward
	other_forward = assigned_forward
	assigned_forward = temp

func _on_ball_entered_attacking_half():
	if mark_incapacitated:
		if randf() < strategy.marking:
			current_behavior = "marking"
		else:
			current_behavior = "chasing"

func _on_mark_incapacitated():
	current_behavior = "marking"
	engagement_decision = ""
	# Stay close but watch for ball
	current_target = assigned_forward.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))

func check_ball_attacking_half():
	if get_attacking_threshhold():
		_on_ball_entered_attacking_half()

func get_attacking_threshhold():
	if !ball:
		return false
	if ball.global_position.y < 0:
		return true
	#TODO: update for different field shapes
	return false

func check_help_exit_behavior():
	if mark_incapacitated:
		current_behavior = "doubling"
		
func handle_double_team_defense():
	if global_position.distance_to(other_forward.global_position) > attributes.aggression - 25:
		navigation_agent.target_position = other_forward.global_position
	else:
		attempt_attack(other_forward.global_position)

func should_help():
	if assigned_forward.global_position.distance_to(defending_goal_position) > 50 and (other_forward.current_behavior == "bull_rush" or other_forward.current_behavior == "speed_rush"):
		return true
	if other_forward.global_position.distance_to(defending_goal_position) < 50 and (other_forward.current_behavior == "bull_rush" or other_forward.current_behavior == "speed_rush") and !(assigned_forward.current_behavior == "bull_rush" or assigned_forward.current_behavior == "speed_rush"):
		return true
	if other_forward.is_in_pass_mode and assigned_forward.is_in_pass_mode:
		return true     
	return false

func set_aim_point():
	if opp_keeper.global_position.distance_squared_to(oppGoal) > buddy_keeper.distance_squared_to(defending_goal_position):
		aim_point = oppGoal
	else:
		var rand = randi_range(0, 5)
		if !plays_left_side:
			rand = rand + 6 #right side aim points are in the second half of the array
		aim_point = aim_selection[rand]
		if aim_point.distance_squared_to(defending_goal_position) < global_position.distance_squared_to(defending_goal_position):
			aim_point.y = randf_range(-20,20)#shoot it somewhere in the middle

func clamp_target_position():
	if defending_goal_position.y < 0:
		if navigation_agent.target_position.y > 0:
			navigation_agent.target_position = Vector2(navigation_agent.target_position.x, 0)
	elif defending_goal_position.y > 0:
		if navigation_agent.target_position.y < 0:
			navigation_agent.target_position = Vector2(navigation_agent.target_position.x, 0)
			
func handle_goalkeeping_movement():
	if !ball:
		return
	var goal_center: Vector2 = (leftPost + rightPost) / 2
	var goal_width: float = rightPost.distance_to(leftPost)
		
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
		#relative_x = clamp(variance_x, goal_center.x - max_goal_offset, goal_center.x + max_goal_offset)
		navigation_agent.target_position = Vector2(relative_x + variance_x, leftPost.y + 10)
		
func handle_trapping():
	#print("I'm trapping")
	if !ball:
		return
		
	var trap_position = Vector2.ZERO
	
	if assigned_forward.global_position.distance_to(global_position) < attributes.aggression / 3: #16-33
		last_behavior = "trapping"
		current_behavior = "fencing"
		return
	elif other_forward.global_position.distance_to(global_position) < attributes.aggression / 3:
		last_behavior = "trapping"
		current_behavior = "fencing"
		return
	
	# Basic position based on defending goal side
	if defending_goal_position.y < 0:
		trap_position.y = -8  # Just over midfield on our defensive side
	else:
		trap_position.y = 8   # Just over midfield on our defensive side
	trap_position.x = ball.global_position.x
	
	# Add some randomness based on positioning skill
	var positioning_randomness = (100 - attributes.positioning) / 2.0
	trap_position.x += randf_range(-positioning_randomness, positioning_randomness)
	
	navigation_agent.target_position = trap_position
	var direction = global_position.direction_to(trap_position)
	velocity = direction * attributes.speed
	move_and_slide()

func chase_ball():
	if !ball:
		return
		
	# Check if ball is in our attacking half (similar to Forward's check)
	if defending_goal_position.y > 0 and ball.global_position.y < 0 or defending_goal_position.y < 0 and ball.global_position.y > 0:
		if should_play_zone:
			current_behavior = "trapping"
		else:
			current_behavior = "marking"
		return
		
	rebound_projection_accuracy = 0.5 + (attributes.positioning / 200.0)
	predict_ball_path_with_rebounds()
	var intercept = find_intercept_point()
	
	if intercept == null:
		return
		
	# Similar position check as Forward's rebound behavior
	if defending_goal_position.y < 0 and intercept.y > 0 or defending_goal_position.y > 0 and intercept.y < 0:
		if should_play_zone:
			current_behavior = "trapping"
		else:
			current_behavior = "marking"
		return
	elif global_position.distance_to(intercept) < 5: #close enough, wait for the ball
		velocity = Vector2.ZERO
	else:
		var direction = global_position.direction_to(intercept)
		navigation_agent.target_position = intercept
		velocity = attributes.speed * direction
		is_sprinting = false
		move_and_slide()

func predict_ball_path_with_rebounds():
	if !ball:
		current_behavior = "marking"
		return
		
	predicted_ball_path = [] # Clear previous prediction
	# Get current ball state
	var current_pos = ball.global_position
	var current_vel = ball.linear_velocity
	var current_spin = ball.current_spin
	var remaining_speed = current_vel.length()
	var time_step = 0.1  # seconds per prediction step
	var max_time = 3.0   # maximum prediction time (3 seconds)
	var field_bounds = Rect2(Vector2(-60, -120), Vector2(60, 120))  #TODO: other types of field
	var projection_error = (1.0 - rebound_projection_accuracy) * 0.5
	var elapsed_time = 0.0
	var steps = 0
	var max_steps = int(max_time / time_step)
	
	while remaining_speed > 50 and steps < max_steps and elapsed_time < max_time:
		var next_pos = current_pos + current_vel * time_step
		var collision = false
		var wall_normal = Vector2.ZERO
		if next_pos.x < field_bounds.position.x:
			wall_normal = Vector2.RIGHT
			collision = true
		elif next_pos.x > field_bounds.end.x:
			wall_normal = Vector2.LEFT
			collision = true
		elif next_pos.y < field_bounds.position.y:
			wall_normal = Vector2.UP
			collision = true
		elif next_pos.y > field_bounds.end.y:
			wall_normal = Vector2.DOWN
			collision = true
		if collision:
			var bounce_vel = current_vel.bounce(wall_normal)
			if current_spin != 0:
				var spin_effect = current_spin * ball.spin_curve_factor * time_step * (1.0 + randf_range(-projection_error, projection_error))
				var perpendicular = bounce_vel.normalized().rotated(PI/2)
				bounce_vel += perpendicular * spin_effect
			var drag = ball.bounce_drag * (1.0 + randf_range(-projection_error*0.5, projection_error*0.5))
			bounce_vel = bounce_vel * drag
			current_vel = bounce_vel
			current_spin *= 0.8 * (1.0 + randf_range(-projection_error*0.5, projection_error*0.5))
			if wall_normal.x != 0:  # Left/right wall
				next_pos.x = field_bounds.position.x if wall_normal.x > 0 else field_bounds.end.x
			else:  # Front/back wall
				next_pos.y = field_bounds.position.y if wall_normal.y > 0 else field_bounds.end.y
		else:
			var drag = 0.98 * (1.0 + randf_range(-projection_error*0.2, projection_error*0.2))
			current_vel = current_vel * drag
		predicted_ball_path.append({
			"position": next_pos,
			"time": elapsed_time,
			"velocity": current_vel
		})
		current_pos = next_pos
		remaining_speed = current_vel.length()
		elapsed_time += time_step
		steps += 1

func find_intercept_point():
	current_intercept_point = defending_goal_position # Default to goal position
	if predicted_ball_path.is_empty():
		return current_intercept_point
	
	var best_intercept = null
	var best_time = INF
	
	for point in predicted_ball_path:
		var point_pos = point.position
		var point_time = point.time
		
		var distance_to_point = global_position.distance_to(point_pos)
		var time_to_reach = distance_to_point / (attributes.speed * 10)
		
		if time_to_reach <= point_time * 1.1:
			if point_time < best_time:
				best_time = point_time
				best_intercept = point_pos
	
	if best_intercept:
		current_intercept_point = best_intercept
	return current_intercept_point
	
func on_shot_at_goal(shot_from: Vector2, shot_direction: Vector2, shooter_team: int):
	if current_behavior != "trapping" and current_behavior != "goalkeeping" and current_behavior != "blocking" and current_behavior != "escorting":#not my job
		return
	if shooter_team == team: #not my problem
		return 
	var intercept
	var reaction_time = map_attribute_to_reaction_time(attributes.reactions)
	await get_tree().create_timer(reaction_time).timeout
	if current_behavior == "goalkeeping": #meet the ball at the goal
		intercept = shot_from + shot_direction * ((leftPost.y - shot_from.y) / shot_direction.y)
	else: #meet the ball where we are
		intercept = shot_from + shot_direction * ((global_position.y - shot_from.y) / shot_direction.y)
	var goal_width = leftPost.distance_to(rightPost)
	if !is_controlling_player and !is_stunned:
		ball_last_sighted = shot_from
		ball_direction_projection = shot_direction
		if current_behavior != "blocking":
			last_behavior = current_behavior
		current_behavior = "blocking"

func map_attribute_to_reaction_time(reaction_rating: float) -> float:
	# Higher rating = faster reaction (shorter delay)
	var normalized = 1.0 - (reaction_rating / 99.0)
	return lerp(MIN_REACTION_TIME, MAX_REACTION_TIME, normalized)
	
func perform_blocking():
	#print("Not in my house")
	var goal_line = leftPost.y
	var time_to_goal
	if last_behavior == "trapping":
		time_to_goal = (0 - ball_last_sighted.y) / ball_direction_projection.y #blocking at midfield, not the goal
	else:
		time_to_goal = (goal_line - ball_last_sighted.y) / ball_direction_projection.y
	var intercept = ball_last_sighted + (ball_direction_projection * time_to_goal)
	if intercept.distance_to(defending_goal_position) > max_goal_offset:
		current_behavior = last_behavior
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
	
func perform_fencing():
	if assigned_forward.global_position.distance_squared_to(global_position) < other_forward.global_position.distance_squared_to(global_position):
		current_opponent = assigned_forward
	else:
		current_opponent = other_forward
	if !current_opponent or current_opponent.is_stunned or _should_break_fencing():
		current_behavior = last_behavior
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
		_make_combat_decision(current_opponent.global_position,current_dist)
		
func _should_break_fencing() -> bool:
	return ball and global_position.distance_to(ball.global_position) < fencing_params["ball_proximity_threshold"] * (1.1 - attributes.reactions/100.0)
	
func perform_escorting():
	#print("I'm here baby")
	if buddy_keeper.is_stunned and global_position.distance_squared_to(defending_goal_position) < buddy_guard.global_position.distance_squared_to(defending_goal_position):
		handle_goalkeeping_movement()
		return
	var rel_position = Vector2(0,0)
	if defending_goal_position.y < 0:
		if plays_left_side:
			rel_position = Vector2(strategy.escort_distance, -strategy.escort_distance)
		else:
			rel_position = Vector2(-strategy.escort_distance, -strategy.escort_distance)
	else:
		if plays_left_side:
			rel_position = Vector2(-strategy.escort_distance, strategy.escort_distance)
		else:
			rel_position = Vector2(strategy.escort_distance, strategy.escort_distance)
	if assigned_forward.global_position.distance_to(buddy_keeper.global_position) < attributes.aggression/2 or other_forward.global_position.distance_to(buddy_keeper.global_position) < attributes.aggression/2:
		last_behavior = "escorting"
		current_behavior = "hunting"
	else:
		navigation_agent.target_position = buddy_keeper.global_position + rel_position
		var direction = global_position.direction_to(buddy_keeper.global_position + rel_position)
		if buddy_keeper.is_sprinting and status.boost > 0.5:
			is_sprinting = true
			velocity = direction * attributes.sprint_speed
		else:
			velocity = attributes.speed * direction

func perform_hunting():
	if !current_opponent or current_opponent.is_stunned:
		current_behavior = "escorting"
		return
	else:
		var direction = global_position.direction_to(current_opponent.global_position)
		var distance = global_position.distance_to(current_opponent.global_position)
		if distance < attributes.aggression / 3 and status.momentum < 10:
			last_behavior = "escorting"
			current_behavior = "fencing"
		elif status.boost > 0:
			is_sprinting = true
			velocity = direction * attributes.sprint_speed
		else:
			is_sprinting = false
			velocity = direction * attributes.speed
