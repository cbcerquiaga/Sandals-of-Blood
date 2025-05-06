extends Player
class_name Forward

# Forward-Specific Attributes
@export var pass_tendency: float = 0.3  # 0-1 likelihood to pass to teammate
@export var switch_cooldown: float = 5.0  # Seconds between side switches

var goal_position = Vector2(0,0)
var assigned_guard: Guard = null
var opposing_keeper: Keeper = null
var forward_partner: Forward = null
var can_switch_sides: bool = true
var last_switch_time: float = 0.0
var current_strategy: String = "positioning"  # "positioning" or "attacking"
var guard_approach = "" #used for AI decision making
var is_in_pass_mode = false #tells the ball to go to the goal or the teammate

func _ready():
	super._ready()
	position_type = "forward"
	$SwitchCooldown.wait_time = switch_cooldown
	$SwitchCooldown.timeout.connect(_on_switch_cooldown_timeout)

func _physics_process(delta):
	super._physics_process(delta)
	
	if not is_controlling_player:
		update_ai_behavior(delta)
	else:
		handle_human_input(delta)

func handle_human_input(delta):
	super.handle_human_input(delta)
	if Input.is_action_just_pressed("switch_sides") and can_switch_sides:
		attempt_side_switch()

func update_ai_behavior(delta):
	if !ball:
		return
	# Only make decisions when ball is in defensive half
	if ball.global_position.y > get_defensive_threshold():
		if current_strategy == "positioning":
			make_strategy_decision()
		
		execute_current_strategy()

func make_strategy_decision():
	# Use aggression rating to decide strategy
	var rand = randf_range(0,100)
	if rand < attributes.aggression:
		current_strategy = "attacking"
	else:
		current_strategy = "positioning"
	
	# If attacking, decide how to handle guard
	if current_strategy == "attacking" and assigned_guard:
		decide_guard_approach()

func execute_current_strategy():
	match current_strategy:
		"positioning":
			find_scoring_position()
			check_pass_opportunity()
		"attacking":
			execute_attack_plan()

func decide_guard_approach():
	var guard_distance = global_position.distance_to(assigned_guard.global_position)
	var guard_angle = (assigned_guard.global_position - global_position).angle()
	
	# Check if guard is out of position
	if guard_distance > 250 or abs(guard_angle) > PI/3:
		guard_approach = "ignore"
	else:
		# Choose to attack or avoid guard
		if randf() < 0.4 * (attributes.confidence / 100.0):
			guard_approach = "attack_guard"
		else:
			guard_approach = "avoid_" + ("left" if randf() > 0.5 else "right")

func execute_attack_plan():
	var target_position: Vector2
	
	match guard_approach:
		"ignore":
			target_position = opposing_keeper.global_position
		"attack_guard":
			target_position = assigned_guard.global_position
			if global_position.distance_to(target_position) < 100:
				attempt_attack()
		"avoid_left", "avoid_right":
			var avoid_dir = 1.0 if guard_approach == "avoid_right" else -1.0
			var perpendicular = (opposing_keeper.global_position - global_position).normalized().rotated(avoid_dir * PI/4)
			target_position = global_position + perpendicular * 200
	
	navigate_to(target_position)
	
	# Use boost for attack moves
	if guard_approach != "ignore" and status.boost > 30:
		if randf_range(0,1) < 0.6:
			super.attempt_sprint(target_position)
		else:
			attempt_dodge()

func find_scoring_position():
	var ideal_position = goal_position + Vector2(
		randf_range(-150, 150),
		randf_range(200, 300)  # Position in front of goal
	)
	if plays_left_side:
		ideal_position.x -= 100
	else:
		ideal_position.x += 100
	
	# Adjust based on ball position
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
		# Human player - check key press and confidence
		should_pass = (
			Input.is_action_pressed("pass"))
	else:
		# AI - check confidence and pass tendency
		should_pass = (
			randf() < pass_tendency * (attributes.confidence / 100.0) and
			global_position.distance_to(forward_partner.global_position) < 600
		)
	
	if should_pass:
		is_in_pass_mode = true
	else:
		is_in_pass_mode = false

func attempt_side_switch():
	if not can_switch_sides or not forward_partner:
		return
	
	# Swap positions with partner
	var my_pos = global_position
	var partner_pos = forward_partner.global_position
	
	navigate_to(partner_pos)
	forward_partner.navigate_to(my_pos)
	
	# Update position labels if needed
	if position_type.ends_with("_l"):
		position_type = position_type.replace("_l", "_r")
	else:
		position_type = position_type.replace("_r", "_l")
	
	# Start cooldown
	can_switch_sides = false
	$SwitchCooldown.start()
	last_switch_time = Time.get_ticks_msec() / 1000.0

func attempt_dodge():
	if not assigned_guard or is_spinning or status.boost < 15:
		return
	
	# Calculate dodge success probability based on factors
	var dodge_success_chance = calculate_dodge_success()
	
	# Only dodge if we have good chance of success
	if dodge_success_chance >= 0.65:  # 65% minimum threshold
		start_spin()
		
		# If we predicted an attack, counterattack
		if is_guard_attacking_soon():
			await get_tree().create_timer(0.2).timeout  # Small delay for dramatic effect
			attempt_counterattack()

func calculate_dodge_success() -> float:
	var base_chance = 0.5
	var guard_attack_prob = predict_guard_attack()
	
	# Factors affecting dodge success
	var confidence_bonus = attributes.confidence / 200.0  # +0% to +50%
	var speed_advantage = (attributes.speed - assigned_guard.attributes.speed) / 500.0
	var energy_advantage = (status.energy - assigned_guard.energy) / 200.0
	var distance_factor = 1.0 - (global_position.distance_to(assigned_guard.global_position) / 300.0)
	
	# Combine factors (clamped to 0-1 range)
	var success_chance = clamp(
		base_chance + 
		(guard_attack_prob * 0.3) +  # More effective against imminent attacks
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
	
	# Calculate attack probability based on:
	var attack_prob = 0.0
	
	# 1. Guard's aggression rating
	attack_prob += assigned_guard.attributes.aggression / 100.0 * 0.4
	
	# 2. Distance to ball (closer = more likely)
	var guard_to_ball_dist = assigned_guard.global_position.distance_to(ball.global_position)
	attack_prob += (1.0 - clamp(guard_to_ball_dist / 400.0, 0.0, 1.0)) * 0.3
	
	# 3. Relative angle (facing player = more likely)
	var guard_facing = assigned_guard.velocity.normalized() if assigned_guard.velocity.length() > 10 else assigned_guard.transform.x
	var to_player_dir = (global_position - assigned_guard.global_position).normalized()
	var angle_factor = 1.0 - (guard_facing.angle_to(to_player_dir) / PI)
	attack_prob += angle_factor * 0.3
	
	return clamp(attack_prob, 0.0, 1.0)

func is_guard_attacking_soon() -> bool:
	if not assigned_guard:
		return false
	
	# Check if guard is winding up an attack
	if assigned_guard.has_method("is_attacking") and assigned_guard.is_attacking():
		return true
	
	# Predictive check
	var attack_prob = predict_guard_attack()
	return attack_prob > 0.75 and global_position.distance_to(assigned_guard.global_position) < 150

func attempt_counterattack():
	if status.boost < 20 or is_spinning:
		return
	
	# Quick counterattack after successful dodge
	status.boost -= 20
	$AttackArea.monitoring = true
	$CounterattackTimer.start(0.3)  # Brief attack window
	
	# Visual feedback
	$CounterattackParticles.emitting = true
	$CounterattackAnimation.play("counter")

func _on_counterattack_timer_timeout():
	$AttackArea.monitoring = false

func _on_switch_cooldown_timeout():
	can_switch_sides = true

func get_defensive_threshold() -> float:
	# Returns y-value that separates defensive/offensive halves
	#TODO: check field type road, wide road, culdusac, left-horseshoe, right-horseshoe
	return 0

func set_assigned_guard(guard: Guard):
	assigned_guard = guard

func set_forward_partner(partner: Forward):
	forward_partner = partner

func navigate_to(position: Vector2):
	if $NavigationAgent.is_navigation_finished():
		$NavigationAgent.target_position = position
