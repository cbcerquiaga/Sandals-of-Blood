extends Player
class_name Guard

# AI Behavior Parameters
@export var aggression: float = 0.6 # 0-1, determines attack tendency
@export var anticipation: float = 0.5 # 0-1, predicts forward movement
@export var discipline: float = 0.7 # 0-1, likelihood to stay with mark

# Mark tracking
var defending_goal_position: Vector2
var buddy_keeper: Keeper = null
var assigned_forward: Forward = null
var other_forward: Forward = null
var forward_last_intent: String = ""
var forward_last_position: Vector2
var forward_last_velocity: Vector2
var mark_incapacitated: bool = false

# Navigation
var current_target: Vector2
var current_behavior: String = "marking"
var engagement_decision: String = ""
var path_update_timer: float = 0

# Nodes
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var intent_timer: Timer = $DecisionTimer

func _ready():
	super._ready()
	position_type = "guard"
	intent_timer.wait_time = 0.5 # Reevaluate forward intent twice per second
	intent_timer.timeout.connect(_on_intent_timer_timeout)

func assign_forward(forward: Forward):
	assigned_forward = forward
	mark_incapacitated = false

func _physics_process(delta):
	super._physics_process(delta)
	
	if not is_controlling_player and can_move:
		check_ball_attacking_half()
		#update_ai_movement(delta)
		#update_forward_tracking(delta)
		

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
		update_navigation_path()
		path_update_timer = 0.3 # Update path 3 times per second
	
	if navigation_agent.is_navigation_finished():
		handle_arrival_behavior()
		return
	
	var next_path_pos = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	velocity = direction * attributes.speed
	
	# Handle defensive maneuvers
	if current_behavior == "intercepting":
		handle_intercept_movement(next_path_pos)
	
	move_and_slide()

func update_navigation_path():
	if mark_incapacitated:
		if ball.global_position.distance_to(global_position) < 300:
			current_behavior = "ball_chase"
			current_target = ball.global_position
		else:
			current_behavior = "marking"
			current_target = assigned_forward.global_position
	else:
		match forward_last_intent:
			"positioning":
				handle_positioning_defense()
			"attacking_keeper":
				handle_attack_defense()
			_:
				current_behavior = "marking"
				current_target = assigned_forward.global_position
	
	navigation_agent.target_position = current_target

func handle_positioning_defense():
	var ball_pos = ball.global_position
	
	# Make defensive decision
	var decision_roll = randf()
	if decision_roll < aggression * 0.6: # 60% max chance to attack
		engagement_decision = "attack"
		current_behavior = "engaging"
		current_target = assigned_forward.global_position
	elif decision_roll < aggression: # Remaining aggression % to double team
		if other_forward:
			engagement_decision = "double_team"
			current_behavior = "engaging"
			current_target = other_forward.global_position
		else:
			engagement_decision = "block"
			current_behavior = "blocking"
			current_target = calculate_block_position()
	else:
		engagement_decision = "block"
		current_behavior = "blocking"
		current_target = calculate_block_position()

func handle_attack_defense():
	# Predict forward's movement based on last velocity and anticipation skill
	var predicted_direction = forward_last_velocity.normalized()
	if forward_last_velocity.length() < 50: # Forward not moving much
		predicted_direction = (buddy_keeper.global_position - assigned_forward.global_position).normalized()
	
	# Add some error based on anticipation skill
	var angle_error = (1.0 - anticipation) * PI/4 * (1 if randf() > 0.5 else -1)
	predicted_direction = predicted_direction.rotated(angle_error)
	
	# Decide to intercept or attack
	var attack_chance = aggression * 0.8 # 80% max chance to attack
	if randf() < attack_chance:
		engagement_decision = "attack"
		current_behavior = "engaging"
		current_target = assigned_forward.global_position + predicted_direction * 100
	else:
		engagement_decision = "intercept"
		current_behavior = "intercepting"
		# Position between forward and keeper
		var keeper_pos = buddy_keeper.global_position
		current_target = keeper_pos + (assigned_forward.global_position - keeper_pos) * 0.7

func calculate_block_position() -> Vector2:
	var ball_pos = ball.global_position
	var forward_pos = assigned_forward.global_position
	
	# Calculate position between forward and goal
	var block_pos = defending_goal_position + (forward_pos - defending_goal_position).normalized() * 150
	
	# Adjust based on ball position
	if ball_pos:
		var ball_to_goal = (defending_goal_position - ball_pos).normalized()
		block_pos = ball_pos + ball_to_goal * 120
	
	return block_pos

func handle_arrival_behavior():
	match current_behavior:
		"engaging":
			if engagement_decision == "attack" or engagement_decision == "double_team":
				attempt_attack()
		"intercepting":
			if randf() < 0.3: # 30% chance to dodge when intercepting
				attempt_dodge()

func handle_intercept_movement(place):
	# Use boost strategically when intercepting
	if status.boost > 30 and randf_range(0,1) < 0.4:
		if aggression > 0.7 and randf_range(0,1) < 0.6:
			super.attempt_sprint(place)
		else:
			attempt_dodge()

func attempt_attack():
	if status.boost > 25:
		#start_attack_animation() #TODO: animate
		status.boost -= 25

func attempt_dodge():
	if status.boost > 15:
		start_spin()
		status.boost -= 15

func switch_forward():
	var temp = other_forward
	other_forward = assigned_forward
	assigned_forward = temp

func _on_intent_timer_timeout():
	if assigned_forward and not mark_incapacitated:
		# Guess forward's intent based on movement patterns
		var to_keeper = (buddy_keeper.global_position) - assigned_forward.global_position
		var angle_to_keeper = forward_last_velocity.angle_to(to_keeper)
		
		if abs(angle_to_keeper) < PI/4 and forward_last_velocity.length() > 80:
			forward_last_intent = "attacking_keeper"
		else:
			forward_last_intent = "positioning"

func _on_ball_entered_attacking_half():
	if mark_incapacitated:
		# Check if should chase ball
		if randf() < discipline:
			current_behavior = "marking"
		else:
			current_behavior = "ball_chase"

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
