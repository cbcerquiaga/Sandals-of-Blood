extends Player
class_name Keeper

# Behavior Parameters
@export var aggression: float = 0.5 # 0-1, tendency to leave goal
@export var pass_preference: float = 0.6 # 0-1, likelihood to pass vs shoot
@export var reaction_time: float = 0.2 # Seconds to make decisions

# State
var own_goal: Vector2
var opp_goal: Vector2
var current_action: String = "guarding"
var clear_intent: String = ""
var threat_assessment: float = 0.0
var ball_last_position: Vector2
var ball_last_velocity: Vector2
var oppKeeper
var oppLF
var oppRF
var buddyLF
var buddyRF

# Nodes
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var decision_timer: Timer = $DecisionTimer

func _ready():
	super._ready()
	position_type = "keeper"
	decision_timer.wait_time = reaction_time

func _physics_process(delta):
	super._physics_process(delta)
	
	if not is_controlling_player:
		update_ai_behavior(delta)

func update_ai_behavior(delta):
	if !ball:
		return
	ball_last_velocity = (ball.global_position - ball_last_position) / delta
	ball_last_position = ball.global_position
	
	match current_action:
		"guarding":
			perform_guarding()
		"approaching":
			perform_approaching()
		"clearing":
			execute_clear()
		"retreating":
			perform_retreating()

func perform_guarding():
	# Default guarding position
	var guard_pos = own_goal + (ball.global_position - own_goal).normalized() * 150
	guard_pos = guard_pos.clamp(
		own_goal - Vector2(300, 300), # Keep within reasonable bounds
		own_goal + Vector2(300, 300))
	
	navigation_agent.target_position = guard_pos
	
	# Assess if should challenge ball
	var ball_speed = ball_last_velocity.length()
	var ball_lateral_movement = abs(ball_last_velocity.x) / max(ball_speed, 1.0)
	var ball_curviness = abs(ball.current_curve) if has_method("current_curve") else 0.0
	
	threat_assessment = (
		0.4 * (1.0 - ball_speed / 1000.0) + # Slow balls are less threatening
		0.3 * ball_lateral_movement + # Lateral movement is less threatening
		0.3 * (ball_curviness / 2.0) # Curvy balls are less threatening
	)
	
	if threat_assessment > (1.0 - aggression):
		current_action = "approaching"
		make_clear_decision()

func perform_approaching():
	navigation_agent.target_position = ball.global_position
	
	if navigation_agent.is_navigation_finished():
		current_action = "clearing"
		execute_clear()

func make_clear_decision():
	# Get closest opponent forward
	var closest_opponent = get_closest_opponent()
	var min_opp_dist = global_position.distance_to(closest_opponent)
	
	# Check if opponent is threatening
	var opponent_threat = 0.0
	if closest_opponent and min_opp_dist < 300:
		opponent_threat = 1.0 - (min_opp_dist / 300.0)
	
	# Decision tree
	var options = []
	var weights = []
	
	# 1. Basic clear (safe option)
	options.append("clear")
	weights.append(0.3)
	
	# 2. Direct shot if opponent keeper is out of position
	if oppKeeper and (oppKeeper.is_stunned() or oppKeeper.global_position.distance_to(opp_goal) > 250):
		options.append("shoot_straight")
		weights.append(0.4 * aggression)
	
	# 3. Bank shots
	var left_wall = get_wall_vector("left")
	var right_wall = get_wall_vector("right")
	
	if left_wall:
		options.append("bank_left")
		weights.append(0.2 * (1.0 - pass_preference))
		options.append("multi_left")
		weights.append(0.1 * (1.0 - pass_preference))
	
	if right_wall:
		options.append("bank_right")
		weights.append(0.2 * (1.0 - pass_preference))
		options.append("multi_right")
		weights.append(0.1 * (1.0 - pass_preference))
	
	# 4. Passing options	
	if buddyLF and buddyLF.global_position.distance_to(ball.global_position) < 600:
		options.append("pass_left")
		weights.append(0.3 * pass_preference)
	
	if buddyRF and buddyRF.global_position.distance_to(ball.global_position) < 600:
		options.append("pass_right")
		weights.append(0.3 * pass_preference)
	
	# 5. Corner delays
	options.append("corner_left")
	weights.append(0.1 * (1.0 - aggression))
	options.append("corner_right")
	weights.append(0.1 * (1.0 - aggression))
	
	# Adjust weights based on opponent threat
	if opponent_threat > 0.5:
		for i in options.size():
			if options[i] in ["pass_left", "pass_right", "multi_left", "multi_right"]:
				weights[i] *= 0.5 # Reduce complex options under pressure
			elif options[i] in ["clear", "corner_left", "corner_right"]:
				weights[i] *= 1.5 # Favor safe options
	
	# Make weighted random choice
	clear_intent = weighted_random_choice(options, weights)

func execute_clear():
	
	match clear_intent:
		"clear":
			# Basic clear - just hit ball away
			var clear_dir = (ball.global_position - own_goal.normalized())
			ball.apply_force(clear_dir * 800)
		
		"shoot_straight":
			# Direct shot at goal
			var shot_dir = (opp_goal - ball.global_position).normalized()
			ball.apply_force(shot_dir * 1000)
		
		"bank_left":
			# Bank off left wall
			var wall_pos = get_wall_position("left")
			var reflect_dir = (wall_pos - ball.global_position).normalized().bounce(Vector2(1, 0))
			ball.apply_force(reflect_dir * 900)
		
		"bank_right":
			# Bank off right wall
			var wall_pos = get_wall_position("right")
			var reflect_dir = (wall_pos - ball.global_position).normalized().bounce(Vector2(-1, 0))
			ball.apply_force(reflect_dir * 900)
		
		"multi_left":
			# Multiple bounces left wall
			var wall_pos = get_wall_position("left")
			var shallow_dir = (wall_pos - ball.global_position).normalized().bounce(Vector2(0.8, 0.6))
			ball.apply_force(shallow_dir * 750)
		
		"multi_right":
			# Multiple bounces right wall
			var wall_pos = get_wall_position("right")
			var shallow_dir = (wall_pos - ball.global_position).normalized().bounce(Vector2(-0.8, 0.6))
			ball.apply_force(shallow_dir * 750)
		
		"pass_left":
			# Pass to left forward
			var forward = get_teammate_forward("left")
			if forward:
				var pass_dir = (forward.global_position - ball.global_position).normalized()
				ball.apply_force(pass_dir * 700)
		
		"pass_right":
			# Pass to right forward
			var forward = get_teammate_forward("right")
			if forward:
				var pass_dir = (forward.global_position - ball.global_position).normalized()
				ball.apply_force(pass_dir * 700)
		
		"corner_left":
			# Send to left corner
			var corner_pos = Vector2(opp_goal.x + 200, opp_goal.y)#GameManager.get_field_corner("left")#TODO: update for field types
			var corner_dir = (corner_pos - ball.global_position).normalized()
			ball.apply_force(corner_dir * 600)
		
		"corner_right":
			# Send to right corner
			var corner_pos = Vector2(opp_goal.x - 200, opp_goal.y)#GameManager.get_field_corner("right")#TODO: update for field types
			var corner_dir = (corner_pos - ball.global_position).normalized()
			ball.apply_force(corner_dir * 600)
	
	current_action = "retreating"

func perform_retreating():
	navigation_agent.target_position = own_goal
	
	if navigation_agent.is_navigation_finished():
		current_action = "guarding"

func handle_opponent_proximity():
	var closest_opponent = get_closest_opponent()
	if not closest_opponent:
		return
	
	var dist = closest_opponent.global_position.distance_to(global_position)
	if dist < 150: # Danger zone
		var decision = randf()
		
		if decision < aggression * 0.5: # Attack
			super.attempt_attack()
		elif decision < aggression: # Sprint challenge
			super.attempt_sprint(ball.position)
		elif decision < 0.7: # Dodge
			attempt_dodge()
		else: # Retreat
			current_action = "retreating"

func weighted_random_choice(options: Array, weights: Array):
	var total_weight = 0.0
	for w in weights:
		total_weight += w
	
	var roll = randf() * total_weight
	var cumulative = 0.0
	
	for i in options.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return options[i]
	
	return options[0] # Fallback

func _on_ball_changed_direction():
	if current_action == "guarding":
		decision_timer.start() # Re-evaluate after brief delay

func get_teammate_forward(side: String) -> Player:
	var forwards = get_tree().get_nodes_in_group("team_%s_forwards" % team)
	for forward in forwards:
		if side == "left" and forward.global_position.x < global_position.x:
			return forward
		elif side == "right" and forward.global_position.x >= global_position.x:
			return forward
	return null

func get_wall_position(side: String) -> Vector2:
	var walls = get_tree().get_nodes_in_group("walls")
	for wall in walls:
		if side == "left" and wall.global_position.x < global_position.x:
			return wall.global_position
		elif side == "right" and wall.global_position.x >= global_position.x:
			return wall.global_position
	return Vector2.ZERO
	

func get_wall_vector(side: String) -> Vector2:
	var walls = get_tree().get_nodes_in_group("%s_walls" % side)
	if walls.size() > 0:
		return (walls[0].global_position - global_position).normalized()
	return Vector2.ZERO

func get_closest_opponent() -> Player:
	var distR = global_position.distance_to(oppRF.position)
	var distL = global_position.distance_to(oppLF.position)
	if distR - distL > 50:
		return oppLF
	elif distL - distR > 50:
		return oppRF
	else: #closest might not be most important at that point
		if randf_range(0,100) < attributes.focus: #locked in players look for the fast boi
			if oppRF.attributes.sprint_speed - oppLF.attributes.sprint_speed > 10:
				return oppRF
			elif oppLF.attributes.sprint_speed - oppRF.attributes.sprint_speed > 10:
				return oppLF
			else: #both pretty fast, better just guess
				if randf_range(0,1) > 0.5:
					return oppLF
				else:
					return oppRF
		else: #dude is not locked in. Eyes naturally drift to the big guy
			if oppRF.bio.pounds > oppLF.bio.pounds + 10: #meaty guy check
				return oppRF
			elif oppLF.bio.pounds > oppRF.bio.pounds + 10:
				return oppLF
			elif (oppRF.bio.feet * 12 + oppRF.bio.inches) > (oppLF.bio.feet * 12 + oppLF.bio.inches):#tree-like guy check
				return oppRF
			elif (oppLF.bio.feet * 12 + oppLF.bio.inches) > (oppRF.bio.feet * 12 + oppRF.bio.inches):
				return oppLF
			else:
				return oppRF

func attempt_dodge():
	var opponent = get_closest_opponent()
	if not opponent or is_spinning or status.boost < 15:
		return

	# Calculate dodge success probability
	var dodge_success_chance = calculate_dodge_success(opponent)

	# Only dodge if we have good chance of success
	if dodge_success_chance >= 0.6:  # 60% minimum threshold for keepers
		start_spin()
		
		# If we predicted an attack, counterattack
		if is_opponent_attacking_soon(opponent):
			await get_tree().create_timer(0.15).timeout  # Shorter delay for keepers
			attempt_counterattack(opponent)

func calculate_dodge_success(opponent: Player) -> float:
	if not opponent:
		return 0.0

	var base_chance = 0.4  # Keepers are less agile than forwards

	# Factors affecting dodge success
	var balance_bonus = attributes.balance / 250.0  # +0% to +40%
	var speed_ratio = attributes.speed / opponent.attributes.speed
	var energy_advantage = (status.energy - opponent.status.energy) / 200.0
	var distance_factor = 1.0 - (global_position.distance_to(opponent.global_position) / 250.0)

	# Combine factors (clamped to 0-1 range)
	var success_chance = clamp(
		base_chance + 
		balance_bonus +
		(speed_ratio - 1.0) * 0.2 +
		energy_advantage +
		(distance_factor * 0.15),
		0.0, 1.0
	)

	return success_chance

func is_opponent_attacking_soon(opponent: Player) -> bool:
	if not opponent:
		return false

	# Check if opponent is winding up an attack
	if opponent.has_method("is_attacking") and opponent.is_attacking():
		return true

	# Predictive check
	var attack_vector = opponent.velocity.normalized()
	var to_keeper = (global_position - opponent.global_position).normalized()
	var angle = attack_vector.angle_to(to_keeper)

	return (
		opponent.velocity.length() > 300 and 
		abs(angle) < PI/4 and 
		global_position.distance_to(opponent.global_position) < 200
	)

func attempt_counterattack(target: Player):
	if status.boost < 15 or is_spinning:
		return

	# Quick counterattack after successful dodge
	status.boost -= 15
	$AttackArea.monitoring = true
	$CounterattackTimer.start(0.25)  # Brief attack window

	# Visual feedback
	$CounterattackParticles.emitting = true
	$CounterattackAnimation.play("keeper_counter")

func _on_counterattack_timer_timeout():
	$AttackArea.monitoring = false
