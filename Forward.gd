extends Player
class_name Forward

# Forward-Specific Attributes
@export var pass_tendency: float = 0.3  # 0-1 likelihood to pass to teammate
@export var switch_cooldown: float = 5.0  # Seconds between side switches

var goal_position = Vector2(0,0)
var assigned_guard: Guard = null
var opposing_keeper: Keeper = null
var forward_partner: Forward = null
var other_guard: Guard = null
var buddy_keeper: Keeper = null
var can_switch_sides: bool = true
var last_switch_time: float = 0.0
var current_strategy: String = "positioning"  # "positioning" or "attacking"
var guard_approach = "" #used for AI decision making
var is_in_pass_mode = false #tells the ball to go to the goal or the teammate

var decision_frames: int = 0 #when the player will decide how to attack
var current_decision_frame: int = 0

var behavior_cooldowns = {}
var last_behavior_change = 0.0

# Behavior-specific variables
var waiting_point: Vector2 = Vector2.ZERO
var target_man_position: Vector2 = Vector2.ZERO
var shooter_position: Vector2 = Vector2.ZERO
var aim_point: Vector2 = Vector2.ZERO
var is_in_slot: bool = false
var predicted_ball_path: Array = []
var current_intercept_point: Vector2 = Vector2.ZERO
var rebound_projection_accuracy: float = 1.0
var bullied_opponent: Player = null
var is_circling: bool = false
var circle_direction: float = 1.0
var safe_area_center: Vector2 = Vector2.ZERO
var panic_distance: float = 300.0
var is_avoiding_guard: bool = false

@onready var navigation_agent = $NavigationAgent2D


func _ready():
	forward_strategy = {
	"bull_rush": 50.0,
	"skill_rush": 100.0,
	"target_man": 100.0,
	"shooter": 100.0,
	"rebound": 50.0,
	"pick": 10.0,
	"bully": 10.0,
	"fencing": 5.0,
	"cower": 5.0,
	"defend": 0
}
	z_index = 2
	behaviors = ["bull_rush", "skill_rush", "target_man", "shooter", "rebound", "pick", "bully", "fencing", "cower", "returning"]
	current_behavior = "bull_rush"
	super._ready()
	position_type = "forward"
	decision_frames = 100 - (attributes.reactions)/2 #between 50 and 75 frames
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 10.0
	$SwitchCooldown.wait_time = switch_cooldown
	$SwitchCooldown.timeout.connect(_on_switch_cooldown_timeout)
	
	# Initialize behavior cooldowns
	for behavior in behaviors:
		behavior_cooldowns[behavior] = 0.0

func _physics_process(delta):
	super._physics_process(delta)
	if !can_move:
		velocity = Vector2.ZERO
		return
	
	# Update behavior cooldowns
	for behavior in behavior_cooldowns:
		behavior_cooldowns[behavior] = max(0.0, behavior_cooldowns[behavior] - delta * 0.5)
	
	if not is_controlling_player and can_move:
		update_ai_behavior(delta)
		clamp_target_position()
		if team == 1:
			human_pass_control()
	if !is_in_correct_half(global_position) and !is_controlling_player:
		navigate_to(Vector2(global_position.x, 0))
		move_and_slide()
		return
		
	elif is_controlling_player and can_move:
		handle_human_input(delta)
		human_pass_control()
		#if !is_in_half():
			#if !is_stunned:
				#move_towards_half()
	move_and_slide()

func update_ai_behavior(delta):
	if !ball:
		return
	#if is_in_half() == false:
		#current_behavior = "returning"
		#return
	
	if team == 2 and ball.global_position.y > get_defensive_threshold() or team == 1 and ball.global_position.y < get_defensive_threshold():
		make_strategy_decision()
		execute_attack_plan()
		clamp_target_position()

func make_strategy_decision():
	choose_behavior()

func execute_attack_plan():
	match current_behavior:
		"bull_rush":
			execute_bull_rush()
		"skill_rush":
			execute_skill_rush()
		"target_man":
			execute_target_man()
		"shooter":
			execute_shooter()
		"rebound":
			execute_rebound()
		"pick":
			execute_pick()
		"bully":
			execute_bully()
		"fencing":
			perform_fencing()
		"cower":
			execute_cower()
		"defend":
			perform_defending()
		#"returning":
			#print("forward out of position")
			#move_towards_half()
		_:
			var target_position = opposing_keeper.global_position
			navigate_to(target_position)

# --- Behavior Implementations ---

func execute_bull_rush():
	if !opposing_keeper or !assigned_guard:
		return
	
	var rush_line = Line2D.new()
	rush_line.add_point(global_position)
	rush_line.add_point(opposing_keeper.global_position)
	var closest_point = get_closest_point_on_line(rush_line, assigned_guard.global_position)
	var guard_distance_to_line = assigned_guard.global_position.distance_to(closest_point)
	var guard_is_blocking = guard_distance_to_line < 30 and not assigned_guard.is_stunned
	
	if guard_is_blocking:
		navigate_to(assigned_guard.global_position)
		if global_position.distance_to(assigned_guard.global_position) < 60:
			if randf() < 0.7:
				attempt_attack(assigned_guard.global_position)
			else:
				attempt_dodge()
	else:
		navigate_to(opposing_keeper.global_position)
		if global_position.distance_to(opposing_keeper.global_position) < attributes.aggression:
			attempt_attack(opposing_keeper.global_position)
	
	rush_line.queue_free()

func execute_skill_rush():
	if !ball or !opposing_keeper:
		return
	
	check_pass_opportunity()
	
	#if we've beaten our man, make a break for it
	if global_position.distance_squared_to(opposing_keeper.global_position) < assigned_guard.global_position.distance_squared_to(opposing_keeper.global_position):
		navigation_agent.target_position = opposing_keeper.global_position
		var direction = global_position.direction_to(opposing_keeper.global_position)
		var speed
		if status.boost > 25:
			is_sprinting = true
			speed = attributes.sprint_speed
		else:
			is_sprinting = false
			speed = attributes.speed
		velocity = direction * speed
		return
	
	if shooter_position == Vector2.ZERO:
		choose_shooter_position()
		return
	
	navigate_to(shooter_position)
	
	if global_position.distance_to(shooter_position) < 10:
		handle_shooter_positioning()
	
	handle_defensive_pressure()

func execute_target_man():
	if !ball:
		return
	is_in_pass_mode = true
	#recalculate target man position every few frames
	if Engine.get_frames_drawn() % 60 == 0:
		calculate_target_man_position()
	#TODO: if distance to target man position is low, focus on avoiding guard and creating passing lane
	
	if assigned_guard && global_position.distance_to(assigned_guard.global_position) < 6:
		if !is_avoiding_guard:
			start_avoiding_guard()
		return
	if global_position.distance_to(ball.global_position) < 20:
		current_behavior = "rebound"
		return
	
	if is_avoiding_guard && (!assigned_guard || global_position.distance_to(assigned_guard.global_position) >= 180):
		is_avoiding_guard = false
	
	create_passing_lane()

func execute_shooter():
	if !ball or !opposing_keeper:
		return
	
	check_pass_opportunity()
	
	if shooter_position == Vector2.ZERO:
		choose_shooter_position()
		return
	
	navigate_to(shooter_position)
	
	if global_position.distance_to(shooter_position) < 50:
		handle_shooter_positioning()
	
	handle_defensive_pressure()

func execute_rebound():
	if !ball:
		return
	if goal_position.y > 0 and ball.global_position.y < 0 or goal_position.y < 0 and ball.global_position.y > 0:
		current_behavior = "target_man"
		return
	if !is_in_correct_half(ball.global_position):
		current_behavior = "target_man"
		return
	
	check_pass_opportunity()
	rebound_projection_accuracy = 0.5 + (attributes.positioning / 200.0)
	predict_ball_path_with_rebounds()
	var intercept = find_intercept_point()
	if intercept == null:
		return
	if !is_in_correct_half(intercept):
		current_behavior = "target_man"
		return
	if goal_position.y < 0 and intercept.y > 0 or goal_position.y > 0 and intercept.y < 0:
		current_behavior = "waiting"
		choose_behavior()
		return
	elif global_position.distance_to(intercept) < 5: #close enough, wait for the ball
		velocity = Vector2.ZERO
	else:
		var direction = global_position.direction_to(intercept)
		navigation_agent.target_position = intercept
		velocity = attributes.speed * direction
		is_sprinting = false
		move_and_slide()
		
func execute_pick():
	if !other_guard:
		return
	if other_guard.is_stunned:
		var sum = forward_strategy.shooter + forward_strategy.bull_rush + forward_strategy.bully + forward_strategy.rebound
		var random = randf_range(0, sum)
		if random < forward_strategy.shooter:
			current_behavior = "shooter"
		elif random < forward_strategy.shooter + forward_strategy.bull_rush:
			current_behavior = "bull_rush"
		elif random < forward_strategy.shooter + forward_strategy.bull_rush + forward_strategy.bully:
			current_behavior = "bully"
		else:
			#TODO: figure out where the "defend is being removed
			if forward_strategy.has("defend"):
				var choice = forward_strategy.rebound + forward_strategy.defend
				var rand = randf_range(0, choice)
				if rand < forward_strategy.defend:
					current_behavior = "defend"
				else:
					current_behavior = "rebound"
			else:
				forward_strategy["defend"] = 25.0
				current_behavior = "rebound"
		return
	var pick_line = Line2D.new()
	pick_line.add_point(global_position)
	pick_line.add_point(other_guard.global_position)
	
	var guard_blocking = false
	if assigned_guard:
		var closest_point = get_closest_point_on_line(pick_line, assigned_guard.global_position)
		var guard_distance_to_line = closest_point.distance_to(assigned_guard.global_position)
		guard_blocking = guard_distance_to_line < 5 and !assigned_guard.is_stunned
	
	if guard_blocking:
		var pick_direction = (other_guard.global_position - global_position).normalized()
		var dodge_direction = pick_direction.rotated(PI/2 * (1 if randf() > 0.5 else -1))
		var dodge_distance = 10
		var dodge_target = global_position + dodge_direction * dodge_distance
		navigation_agent.target_position = dodge_target
		if global_position.distance_to(assigned_guard.global_position) < 20:
			navigation_agent.target_position = other_guard.global_position
			if status.boost > 0:
				is_sprinting = true
	else:
		navigation_agent.target_position = other_guard.global_position
		if global_position.distance_to(assigned_guard.global_position) < 20:
			if status.boost > 0:
				is_sprinting = true
	navigate_to(navigation_agent.target_position)
	pick_line.queue_free()

func execute_bully():
	if !bullied_opponent or !is_instance_valid(bullied_opponent) or !bullied_opponent.is_stunned:
		find_stunned_opponent()
		if !bullied_opponent:
			return
	
	if !bullied_opponent.is_stunned:
		navigate_to(bullied_opponent.global_position)
		if global_position.distance_to(bullied_opponent.global_position) < attributes.aggression/2:
			attempt_attack(bullied_opponent.global_position)
		return
	
	handle_nearby_opponents()
	
	var hover_distance = 20
	var hover_position = bullied_opponent.global_position + Vector2(
		randf_range(-hover_distance, hover_distance),
		randf_range(-hover_distance, hover_distance)
	)
	navigate_to(hover_position)

func execute_cower():
	safe_area_center = Vector2(0, goal_position.y * 0.5)
	
	var threats = []
	if assigned_guard and is_instance_valid(assigned_guard):
		threats.append(assigned_guard)
	if other_guard and is_instance_valid(other_guard):
		threats.append(other_guard)
	if opposing_keeper and is_instance_valid(opposing_keeper):
		threats.append(opposing_keeper)
	
	var closest_threat = null
	var min_threat_distance = INF
	
	for threat in threats:
		var dist = global_position.distance_to(threat.global_position)
		if dist < min_threat_distance:
			min_threat_distance = dist
			closest_threat = threat
	
	if assigned_guard and min_threat_distance < 150 and closest_threat == assigned_guard:
		switch_to_fencing_mode()
		return
	
	var flee_direction = Vector2.ZERO
	if closest_threat:
		flee_direction = (global_position - closest_threat.global_position).normalized()
	
	for threat in threats:
		if threat != closest_threat:
			var away = (global_position - threat.global_position).normalized()
			flee_direction += away * 0.5
	
	if flee_direction != Vector2.ZERO:
		flee_direction = flee_direction.normalized()
		var to_safe = (safe_area_center - global_position).normalized()
		flee_direction = (flee_direction + to_safe * 0.3).normalized()
	
	var target_position = global_position
	if flee_direction != Vector2.ZERO:
		target_position += flee_direction * 400
	else:
		target_position = safe_area_center
	
	var field_width = 1000
	var field_height = abs(goal_position.y)
	
	target_position.x = clamp(target_position.x, -field_width * 0.8, field_width * 0.8)
	target_position.y = clamp(target_position.y, -field_height * 0.8 + goal_position.y, field_height * 0.2 + goal_position.y)
	
	navigate_to(target_position)

# --- Behavior Selection System ---

func choose_behavior():
	# Calculate situational modifiers
	var situational_weights = calculate_situational_weights()
	
	# Combine all weights
	var combined_weights = {}
	var total_weight = 0.0
		
	
	for behavior in behaviors:
		# Base weight is product of team strategy and player preference
		var base_weight = forward_strategy.get(behavior + "_weight", 1.0) * forward_strategy.get(behavior, 1.0)
		
		# Apply situational modifier
		var situational_weight = situational_weights.get(behavior, 1.0)
		
		combined_weights[behavior] = base_weight * situational_weight
		total_weight += combined_weights[behavior]
	
	# Normalize weights
	var normalized_weights = {}
	for behavior in combined_weights:
		normalized_weights[behavior] = combined_weights[behavior] / total_weight
	
	# Choose behavior based on weights
	var random_val = randf()
	var cumulative_weight = 0.0
	
	if forward_partner.current_behavior == "target_man": #favor shooting or rebounding
		combined_weights["shooter"] *= 3
		combined_weights["rebound"] *= 3
	elif forward_partner.current_behavior == "shooter": #favor passing and picking
		combined_weights["pick"] *= 3
		combined_weights["target_man"] *= 3
	elif forward_partner.current_behavior == "rebound": #prioritize picking or shooting
		combined_weights["pick"] *= 3
		combined_weights["shooter"] *= 3
	elif forward_partner.current_behavior == "bull_rush" or forward_partner.current_behavior == "skill_rush":
		combined_weights["target_man"] *= 0.3
	
	for behavior in behaviors:
		cumulative_weight += normalized_weights[behavior]
		if random_val <= cumulative_weight:
			set_behavior(behavior)
			break

func calculate_situational_weights() -> Dictionary:
	var weights = {}
	
	# Default weights
	for behavior in behaviors:
		weights[behavior] = 1.0
	
	# Check for obvious situations
	if is_guard_vulnerable():
		weights["bull_rush"] *= 3.0
		weights["skill_rush"] *= 2.0
	
	if is_ball_reachable():
		weights["rebound"] *= 2.5
		weights["shooter"] *= 1.5
	
	if has_stunned_opponent():
		weights["bully"] *= 1.5
	
	if is_under_pressure():
		weights["cower"] *= 2.0
		weights["fencing"] *= 1.5
	
	if is_near_goal():
		weights["shooter"] *= 2.0
		weights["bull_rush"] *= 1.5
	
	return weights

func is_guard_vulnerable() -> bool:
	return (assigned_guard and 
			(assigned_guard.is_stunned or 
			 global_position.distance_to(assigned_guard.global_position) > 150))

func is_ball_reachable() -> bool:
	return (ball and 
			global_position.distance_to(ball.global_position) < attributes.speed/1.5 and 
			has_clear_path_to(ball.global_position))

func has_stunned_opponent() -> bool:
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.team != team and player.is_stunned():
			return true
	return false

func is_under_pressure() -> bool:
	var pressure = 0
	if assigned_guard and global_position.distance_to(assigned_guard.global_position) < 200:
		pressure += 1
	if other_guard and global_position.distance_to(other_guard.global_position) < 250:
		pressure += 1
	if opposing_keeper and global_position.distance_to(opposing_keeper.global_position) < 300:
		pressure += 1
	return pressure >= 2

func is_near_goal() -> bool:
	return global_position.distance_to(goal_position) < 50

func set_behavior(new_behavior: String):
	if current_behavior == new_behavior:
		return
	
	# Update cooldowns
	behavior_cooldowns[current_behavior] = 1.0
	
	# Change behavior
	current_behavior = new_behavior
	last_behavior_change = Time.get_ticks_msec() / 1000.0
	
	# Reset behavior-specific variables
	match current_behavior:
		"bull_rush", "skill_rush":
			guard_approach = ""
		"target_man":
			target_man_position = Vector2.ZERO
		"rebound":
			predicted_ball_path = []
		"pick":
			is_circling = false
		"bully":
			bullied_opponent = null
	
	# Emit signal if needed
	if has_signal("behavior_changed"):
		emit_signal("behavior_changed", current_behavior)

func human_pass_control():
	if Input.is_action_pressed("LF_pass") and plays_left_side:
		is_in_pass_mode = true
	elif Input.is_action_pressed("RF_pass") and !plays_left_side:
		is_in_pass_mode = true
	else:
		is_in_pass_mode = false

func find_scoring_position():
	var ideal_position = goal_position + Vector2(
		randf_range(-150, 150),
		randf_range(200, 300)
	)
	if plays_left_side:
		ideal_position.x -= 100
	else:
		ideal_position.x += 100
	
	if ball:
		var ball_to_goal = (goal_position - ball.global_position).normalized()
		ideal_position = ball.global_position + ball_to_goal * 200
	
	navigate_to(ideal_position)

func check_pass_opportunity():
	if not forward_partner:
		is_in_pass_mode = false
		return
	
	var should_pass = false
	
	if is_controlling_player:
		should_pass = Input.is_action_pressed("pass")
	else:
		should_pass = (
			randf() < pass_tendency * (attributes.confidence / 100.0) and
			global_position.distance_to(forward_partner.global_position) < 600
		)
	
	is_in_pass_mode = should_pass

func attempt_side_switch():
	if not can_switch_sides or not forward_partner:
		return
	
	var my_pos = global_position
	var partner_pos = forward_partner.global_position
	
	navigate_to(partner_pos)
	forward_partner.navigate_to(my_pos)
	
	plays_left_side = !plays_left_side
	
	can_switch_sides = false
	$SwitchCooldown.start()
	last_switch_time = Time.get_ticks_msec() / 1000.0

func decide_dodge():
	if not assigned_guard or is_spinning or status.boost < 15:
		return
	
	var dodge_success_chance = calculate_dodge_success()
	
	if dodge_success_chance >= 0.65:
		attempt_dodge()
		
		if is_guard_attacking_soon():
			await get_tree().create_timer(0.2).timeout
			attempt_counterattack()

func calculate_dodge_success() -> float:
	var base_chance = 0.5
	var guard_attack_prob = predict_guard_attack()
	
	var confidence_bonus = attributes.confidence / 200.0
	var speed_advantage = (attributes.speed - assigned_guard.attributes.speed) / 500.0
	var energy_advantage = (status.energy - assigned_guard.status.energy) / 200.0
	var distance_factor = 1.0 - (global_position.distance_to(assigned_guard.global_position) / 300.0)
	
	var success_chance = clamp(
		base_chance + 
		(guard_attack_prob * 0.3) +
		confidence_bonus +
		speed_advantage +
		energy_advantage +
		(distance_factor * 0.2),
		0.0, 1.0
	)
	
	return success_chance

func predict_guard_attack() -> float:
	if not assigned_guard or not is_instance_valid(assigned_guard):
		return 0.0
	
	var attack_prob = 0.0
	
	attack_prob += assigned_guard.attributes.aggression / 100.0 * 0.4
	
	var guard_to_ball_dist = assigned_guard.global_position.distance_to(ball.global_position)
	attack_prob += (1.0 - clamp(guard_to_ball_dist / 400.0, 0.0, 1.0)) * 0.3
	
	var guard_facing = assigned_guard.velocity.normalized() if assigned_guard.velocity.length() > 10 else assigned_guard.transform.x
	var to_player_dir = (global_position - assigned_guard.global_position).normalized()
	var angle_factor = 1.0 - (guard_facing.angle_to(to_player_dir) / PI)
	attack_prob += angle_factor * 0.3
	
	return clamp(attack_prob, 0.0, 1.0)

func is_guard_attacking_soon() -> bool:
	if not assigned_guard:
		return false
	if assigned_guard.status.momentum > 20:
		var to_player = (global_position - assigned_guard.global_position).normalized()
		var guard_direction = assigned_guard.velocity.normalized() if assigned_guard.velocity.length() > 10 else Vector2.ZERO
		# If guard is moving generally toward me (within 90 degrees)
		if guard_direction != Vector2.ZERO and to_player.dot(guard_direction) > 0.5:
			return true
	var attack_prob = predict_guard_attack()
	return attack_prob > 0.75 and global_position.distance_to(assigned_guard.global_position) < 50

func attempt_counterattack():
	if status.boost < 2 or is_spinning:
		return
	
	status.boost -= 2
	$AttackArea.monitoring = true
	$CounterattackTimer.start(0.3)
	#$CounterattackParticles.emitting = true
	#$CounterattackAnimation.play("counter")

func _on_counterattack_timer_timeout():
	$AttackArea.monitoring = false

func _on_attack_timer_timeout():
	$AttackArea.monitoring = false

func _on_switch_cooldown_timeout():
	can_switch_sides = true

func get_defensive_threshold() -> float:
	return 0  # TODO: Implement based on field type

func set_assigned_guard(guard: Guard):
	assigned_guard = guard

func set_forward_partner(partner: Forward):
	forward_partner = partner

func set_other_guard(guard: Guard):
	other_guard = guard

func navigate_to(position: Vector2):
	navigation_agent.target_position = position
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var next_path_pos = navigation_agent.get_next_path_position()
		var stuck = 1
		if is_incapacitated:
			stuck = 0
		velocity = global_position.direction_to(next_path_pos) * attributes.speed * stuck


func choose_shooter_position():
	is_in_slot = randf() > forward_strategy.get("wing_preference", 0.5)
	
	if is_in_slot:
		calculate_slot_position()
	else:
		calculate_wing_position()

func calculate_wing_position():
	var wing_x = waiting_point.x + randf_range(-30, 30)
	var wing_y = lerp(goal_position.y, waiting_point.y, 0.5) + randf_range(-50, 50)
	shooter_position = Vector2(wing_x, wing_y)
	calculate_aim_point()

func calculate_slot_position():
	var predicted_reflection = predict_ball_reflection()
	var slot_x = predicted_reflection.x * 0.8
	var slot_y = lerp(goal_position.y, ball.global_position.y, 0.3)
	shooter_position = Vector2(slot_x, slot_y)
	aim_point = goal_position

func predict_ball_reflection() -> Vector2:
	var ball_to_keeper = (opposing_keeper.global_position - ball.global_position).normalized()
	var positioning_error = 1.0 - (attributes.positioning / 100.0)
	var error_angle = randf_range(-PI/8, PI/8) * positioning_error
	var keeper_facing = Vector2(0, 1) if team == 1 else Vector2(0, -1)
	var reflected_dir = ball_to_keeper.bounce(keeper_facing).rotated(error_angle)
	return opposing_keeper.global_position + (reflected_dir * 300)

func calculate_aim_point():
	var options = [goal_position]
	options.append(goal_position + Vector2(-30, 0))
	options.append(goal_position + Vector2(30, 0))
	
	var best_score = -INF
	for option in options:
		var score = evaluate_aim_point(option)
		if score > best_score:
			best_score = score
			aim_point = option

func evaluate_aim_point(point: Vector2) -> float:
	var score = 0.0
	if opposing_keeper:
		score += (300 - opposing_keeper.global_position.distance_to(point)) / 3.0
	if assigned_guard:
		var to_aim = (point - global_position).normalized()
		var to_guard = (assigned_guard.global_position - global_position).normalized()
		var angle = abs(to_aim.angle_to(to_guard))
		score += (PI - angle) * 20
	score += randf_range(-10, 10)
	return score

func handle_shooter_positioning():
	if global_position.distance_to(ball.global_position) < attributes.reactions/5 and ball.linear_velocity.length() < 50:
		navigate_to(ball.global_position)
		return
	if !is_in_slot:
		adjust_for_clear_paths()
	else:
		if randf() < 0.3:
			calculate_slot_position()

func adjust_for_clear_paths():
	var needs_adjustment = false
	if !has_clear_path_to(goal_position):
		needs_adjustment = true
	if ball && !has_clear_path_to(ball.global_position):
		needs_adjustment = true
	
	if needs_adjustment:
		var attempts = 0
		while attempts < 5:
			var new_x = shooter_position.x + randf_range(-50, 50)
			var new_y = shooter_position.y + randf_range(-50, 50)
			var test_pos = Vector2(new_x, new_y)
			
			if has_clear_path_to(goal_position, test_pos) && has_clear_path_to(ball.global_position, test_pos):
				shooter_position = test_pos
				break
			attempts += 1

func handle_defensive_pressure():
	if !assigned_guard:
		return
	
	var guard_distance = global_position.distance_to(assigned_guard.global_position)
	var keeper_distance = global_position.distance_to(opposing_keeper.global_position) if opposing_keeper else INF
	
	if guard_distance < 20 || keeper_distance < 15:
		decide_defensive_response(guard_distance, keeper_distance)

func decide_defensive_response(guard_dist: float, keeper_dist: float):
	var fencing_chance = 0.3 * (attributes.aggression / 100.0)
	if ball:
		var ball_dist = global_position.distance_to(ball.global_position)
		fencing_chance *= clamp(ball_dist / 300.0, 0.1, 1.0)
	
	if randf() < fencing_chance:
		switch_to_fencing_mode()
	else:
		if keeper_dist < guard_dist && randf() < 0.6:
			attempt_attack(opposing_keeper.global_position)
		elif guard_dist < keeper_dist && randf() < 0.6:
			attempt_attack(assigned_guard.global_position)
		else:
			decide_dodge()

func calculate_target_man_position():
	var path_start = ball.global_position if ball else Vector2.ZERO
	var path_end = goal_position
	if buddy_keeper && buddy_keeper.aim != Vector2.ZERO:
		path_start = buddy_keeper.global_position
		path_end = buddy_keeper.aim
	var path_dir = (path_end - path_start).normalized()
	var path_length = path_start.distance_to(path_end)
	# Find potential intercept points along the path
	var min_x = min(0, waiting_point.x)
	var max_x = max(0, waiting_point.x)
	var goal_y_diff = -20 if goal_position.y < 0 else 20
	
	# Try to find a point along the path between y=0 and goal_y_diff
	var ideal_intercept = null
	var t_values = []
	
	# Sample points along the path
	for i in range(1, 10):
		var t = i / 10.0
		var point = path_start + path_dir * (path_length * t)
		
		# Check if point is between 0 and goal_y_diff on y-axis
		if (goal_position.y < 0 && point.y <= 0 && point.y >= goal_y_diff) || \
		   (goal_position.y > 0 && point.y >= 0 && point.y <= goal_y_diff):
			
			# Check if x and waiting_point.x have same sign
			if (point.x * waiting_point.x >= 0) || abs(point.x) < 20:
				ideal_intercept = point
				break
			else:
				t_values.append(t)
	
	# If no perfect intercept found, find the closest one
	if !ideal_intercept && !t_values.is_empty():
		var mid_t = t_values[t_values.size() / 2]
		ideal_intercept = path_start + path_dir * (path_length * mid_t)
	
	# If still no intercept, choose a random position between 0 and waiting point
	if !ideal_intercept:
		var positioning_randomness = 1.0 - (attributes.positioning / 100.0)
		var random_x = randf_range(min_x, max_x) * positioning_randomness
		ideal_intercept = Vector2(
			random_x,
			lerp(0, goal_y_diff, randf()))
	
	# If too close to assigned guard or opposing keeper, drift wide
	if (assigned_guard and !assigned_guard.is_stunned and ideal_intercept.distance_to(assigned_guard.global_position) < 10) or (opposing_keeper and ideal_intercept.distance_to(opposing_keeper.global_position) < 10 and !opposing_keeper.is_stunned):
		var drift_direction = sign(waiting_point.x) if waiting_point.x != 0 else (1 if randf() > 0.5 else -1)
		var drift_amount = randf_range(50, 150) * (1.0 - (attributes.positioning / 100.0))
		ideal_intercept.x += drift_direction * drift_amount
	# Apply some randomness based on positioning skill
	var positioning_variance = (100 - attributes.positioning) / 2.0
	target_man_position = Vector2(
		ideal_intercept.x + randf_range(-positioning_variance, positioning_variance),
		ideal_intercept.y + randf_range(-positioning_variance, positioning_variance)
	)

func create_passing_lane():
	#print("find the passing lane")
	var passing_path = Line2D.new()
	passing_path.add_point(ball.global_position)
	passing_path.add_point(target_man_position)
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(ball.global_position, target_man_position)
	query.collision_mask = 0b1
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var blocker_position = result.position
		var avoid_direction = (target_man_position - blocker_position).normalized()
		var new_position = target_man_position + (avoid_direction * 2)
		new_position.x = clamp(new_position.x, -50, 50)
		new_position.y = clamp(new_position.y, -100, 100)
		target_man_position = new_position
	
	#print("getting open: " + str(target_man_position) )
	navigate_to(target_man_position)
	passing_path.queue_free()

func start_avoiding_guard():
	is_avoiding_guard = true
	
	if randf() < 0.3:
		switch_to_fencing_mode()
		return
	
	var away_from_guard = (global_position - assigned_guard.global_position).normalized()
	var avoid_position = global_position + (away_from_guard * 200)
	avoid_position.x = clamp(avoid_position.x, -600, 600)
	avoid_position.y = clamp(avoid_position.y, -300, 300)
	navigate_to(avoid_position)

func switch_to_fencing_mode():
	current_behavior = "fencing"
	perform_fencing()

func predict_ball_path_with_rebounds():
	if !ball:
		predicted_ball_path = [waiting_point]#if in dobut, go to happy place
		return
	predicted_ball_path = [] # Clear previous prediction
	# Get current ball state
	var current_pos = ball.global_position
	var current_vel = ball.linear_velocity
	var current_spin = ball.current_spin
	var remaining_speed = current_vel.length()
	var time_step = 0.1  # seconds per prediction step
	var max_time = 3.0   # maximum prediction time (3 seconds)
	var field_bounds = Rect2(Vector2(-60, -120), Vector2(60, 120))  # TODO: other types of field
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
	current_intercept_point = waiting_point
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

func handle_obstacles_to_intercept():
	if current_intercept_point == Vector2.ZERO:
		return
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, current_intercept_point)
	query.collision_mask = 0b1
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var obstacle = result.collider
		var obstacle_pos = result.position
		
		var attack_chance = 0.5 + (attributes.aggression / 200.0)
		
		if randf() < attack_chance:
			attempt_attack(assigned_guard.global_position)
		else:
			var dodge_dir = (current_intercept_point - obstacle_pos).normalized().rotated(randf_range(-PI/4, PI/4))
			var dodge_target = obstacle_pos + dodge_dir * 150
			navigate_to(dodge_target)

func find_stunned_opponent():
	bullied_opponent = null
	var closest_distance = INF
	var players = get_tree().get_nodes_in_group("players")
	
	for player in players:
		if player.team != team and player.is_stunned():
			var distance = global_position.distance_to(player.global_position)
			if distance < closest_distance:
				closest_distance = distance
				bullied_opponent = player
	
	if bullied_opponent:
		circle_direction = 1.0 if randf() > 0.5 else -1.0

func handle_nearby_opponents():
	var nearby_opponents = []
	var players = get_tree().get_nodes_in_group("players")
	
	for player in players:
		if player.team == team or player == bullied_opponent or !is_instance_valid(player):
			continue
		
		if global_position.distance_to(player.global_position) < 200:
			nearby_opponents.append(player)
	
	if !nearby_opponents.is_empty():
		var shielding_success = attempt_shielding(nearby_opponents[0])
		if !shielding_success:
			if randf() < 0.7:
				attempt_dodge()
			else:
				attempt_attack(nearby_opponents[0].global_position)

func attempt_shielding(opponent: Player) -> bool:
	var to_opponent = (opponent.global_position - bullied_opponent.global_position).normalized()
	var shield_position = bullied_opponent.global_position - to_opponent * 80
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, shield_position)
	query.collision_mask = 0b1
	
	var result = space_state.intersect_ray(query)
	if result:
		var circle_pos = bullied_opponent.global_position + (global_position - bullied_opponent.global_position).rotated(circle_direction * PI/4).normalized() * 100
		navigate_to(circle_pos)
		return false
	else:
		navigate_to(shield_position)
		is_circling = true
		return true

func has_clear_path_to(target: Vector2, from_pos: Vector2 = global_position) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from_pos, target)
	query.collision_mask = 0b1
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return !result
	
func perform_fencing():
	if !current_opponent or current_opponent.is_stunned or _should_break_fencing():
		choose_behavior()
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

func clamp_target_position():
	if !is_in_correct_half(navigation_agent.target_position):
		var clamped_pos = navigation_agent.target_position
		if goal_position.y < 0:
			clamped_pos.y = min(clamped_pos.y, 0)
		else:
			clamped_pos.y = max(clamped_pos.y, 0)
		navigation_agent.target_position = clamped_pos

func is_in_correct_half(pos: Vector2) -> bool:
	if goal_position.y < 0:  #bottom half
		return pos.y <= 0
	else:  #top half
		return pos.y >= 0
		
#shadow the opposing goalkeeper, try to take away any passes
func perform_defending():
	var desired_position: Vector2
	var own_goal = Vector2(0, 0 - goal_position.y)
	var read
	read = randi_range(0,100)
	if read < attributes.positioning: #if we make a good read, we get to know what the keeper is thinking
		var opp_aim = opposing_keeper.aim
		if aim.distance_to(assigned_guard.global_position) < 10: #passing to our guard
			desired_position = (assigned_guard.global_position + opposing_keeper.global_position*2)/3
		elif aim.distance_to(own_goal) < 20: #shooting
			desired_position = (own_goal + opposing_keeper.global_position * 2)/3
		else:
			var temp = (own_goal + assigned_guard.global_position + opposing_keeper.global_position*2) / 4
			desired_position = Vector2((opp_aim.x+temp.x)/2, temp.y)
	else:
		desired_position = (own_goal + assigned_guard.global_position + opposing_keeper.global_position*2) / 4
	if ball.global_position.distance_to(global_position) < (attributes.speedRating + attributes.reactions)/8: #12.5 to 24.75
		execute_rebound()
		return
	navigation_agent.target_position = desired_position
	navigate_to(navigation_agent.target_position)

func get_closest_point_on_line(line: Line2D, point: Vector2) -> Vector2:
	if line.get_point_count() < 2:
		return Vector2.ZERO
	
	var a = line.get_point_position(0)
	var b = line.get_point_position(1)
	var ap = point - a
	var ab = b - a
	var t = clamp(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
	return a + t * ab
