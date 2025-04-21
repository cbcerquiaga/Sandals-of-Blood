class_name Outfielder
extends AirHockeyPlayer

enum AIState { IDLE, CHASING_BALL, ATTACKING, SCORING, DEFENDING }

var current_ai_state: AIState = AIState.IDLE
var target_position: Vector2 = Vector2.ZERO
var target_opponent: Node2D = null

func _ready():
	super._ready()
	set_ai_mode(current_mode)

func _physics_process(delta):
	super._physics_process(delta)
	
	if not is_player_controlled:
		ai_behavior(delta)

func set_ai_mode(mode: BehaviorMode):
	current_mode = mode
	match mode:
		BehaviorMode.DEFEND_AREA:
			current_ai_state = AIState.DEFENDING
		BehaviorMode.ATTACK_OUTFIELDER:
			current_ai_state = AIState.ATTACKING
			target_opponent = get_opponent_outfielder()
		BehaviorMode.ATTACK_GOALIE:
			current_ai_state = AIState.ATTACKING
			target_opponent = get_opponent_goalie()
		BehaviorMode.SCORING_POSITION:
			current_ai_state = AIState.SCORING

func ai_behavior(delta):
	match current_ai_state:
		AIState.IDLE:
			idling()
		AIState.CHASING_BALL:
			chase_ball_behavior()
		AIState.ATTACKING:
			attack_behavior()
		AIState.SCORING:
			scoring_behavior()
		AIState.DEFENDING:
			defend_behavior()

func idling():
	# Wait for ball to enter play
	if ball and ball.linear_velocity.length() > 50:
		current_ai_state = AIState.CHASING_BALL

func chase_ball_behavior():
	if not ball:
		current_ai_state = AIState.IDLE
		return
	
	# Move toward ball's predicted position
	target_position = predict_ball_position()
	go(target_position.x, target_position.y, false)
	
	# If close enough, attempt to hit or catch the ball
	if global_position.distance_to(ball.global_position) < 50:
		if randf() < 0.3: # 30% chance to dive for ball
			start_dive()
		
		if ball.height <= height + jump_height:
			if attempt_catch(ball):
				return
			else:
				hit_ball_toward_goal()

func attack_behavior():
	if not target_opponent or not is_instance_valid(target_opponent):
		target_opponent = get_nearest_opponent()
		if not target_opponent:
			current_ai_state = AIState.CHASING_BALL
			return
	
	# Move toward opponent
	go(target_opponent.global_position.x, target_opponent.global_position.x, false)
	
	# If close enough, attack
	if global_position.distance_to(target_opponent.global_position) < 80:
		if not target_opponent.is_spinning and not target_opponent.is_knocked_down:
			attack()
		elif target_opponent.is_spinning:
			# Maybe dodge or wait out the spin
			if randf() < 0.7: # 70% chance to dodge spinning opponent
				start_spin()

func scoring_behavior():
	if not ball:
		current_ai_state = AIState.IDLE
		return
	
	# Move to offensive position
	target_position = get_scoring_position()
	go(target_position.x, target_position.y, false)
	
	# If ball comes near, hit it toward goal
	if global_position.distance_to(ball.global_position) < 100:
		hit_ball_toward_goal()

func defend_behavior():
	# Stay in defend area and intercept balls
	var center = defend_area.position + defend_area.size * 0.5
	go(center.x, center.y, false)
	
	if ball and global_position.distance_to(ball.global_position) < 150:
		current_ai_state = AIState.CHASING_BALL

func move_toward(position: Vector2):
	var direction = (position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func predict_ball_position() -> Vector2:
	if not ball:
		return global_position
	
	# Simple prediction - adjust as needed
	var ball_velocity = ball.linear_velocity
	var time_to_reach = global_position.distance_to(ball.global_position) / speed
	return ball.global_position + ball_velocity * time_to_reach

func hit_ball_toward_goal():
	if not ball:
		return
	
	var goal_position = get_opponent_goal_position()
	var direction = (goal_position - ball.global_position).normalized()
	var hit_power = 800.0 + power * 200.0 # Base power + stat bonus
	
	if "apply_hit" in ball:
		ball.apply_hit(direction * hit_power)

func get_opponent_outfielder() -> Node2D:
	# Implement logic to find opponent outfielder
	return null

func get_opponent_goalie() -> Node2D:
	# Implement logic to find opponent goalie
	return null

func get_nearest_opponent() -> Node2D:
	# Implement logic to find nearest opponent
	return null

func get_opponent_goal_position() -> Vector2:
	# Implement logic to get opponent goal position
	return Vector2(1000, 300) # Example position

func get_scoring_position() -> Vector2:
	# Implement logic to get good scoring position
	return Vector2(800, 300) # Example position

func _on_ball_entered_play(ball_node: RigidBody2D):
	ball = ball_node
	if not is_player_controlled:
		current_ai_state = AIState.CHASING_BALL
