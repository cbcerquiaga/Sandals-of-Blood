class_name Goalie
extends BallPlayer

enum GoalieState {
	DEFENSIVE,    # Protects goal in crease
	AGGRESSIVE,   # Challenges in neutral zone
	VIOLENT,      # Attacks opponents
	MANUAL        # Player-controlled
}

var move_speed: float = 350.0
var dive_power: float = 1200.0
var attack_range: float = 180.0
var zone_boundaries: Array[float] = [0.2, 0.4]  # Defensive/Neutral/Attacking
var dive_cooldown
var can_dive: bool
var spin_timer: float
var is_spinning
var goalie_state
var can_shoot: bool = true
var shot_power: float = 900.0

func _ready():
	is_spinning = false
	can_dive = true
	spin_timer = 0.0
	dive_cooldown = 3.0
	goalie_state = GoalieState.DEFENSIVE

func _physics_process(delta):
	if is_spinning:
		_process_spin(delta)
		return
	
	match goalie_state:
		GoalieState.DEFENSIVE:
			_defend_crease(delta)
		GoalieState.AGGRESSIVE:
			_challenge_ball(delta)
		GoalieState.VIOLENT:
			_attack_opponent(delta)
		GoalieState.MANUAL:
			_manual_control(delta)

func _defend_crease(delta):
	if not ball: return
	
	# Stay between ball and goal center with predictive movement
	var goal_center = Vector2(100, get_viewport_rect().size.y/2)
	var ball_dir = (ball.global_position - goal_center).normalized()
	var block_pos = goal_center + ball_dir * 150  # Lead position
	
	velocity = delta * (block_pos - global_position).normalized() * move_speed
	move_and_slide()

func _challenge_ball(delta):
	if not ball: return
	
	# Move toward ball but stay within neutral zone
	var challenge_x = clamp(ball.global_position.x, 
						  get_viewport_rect().size.x * zone_boundaries[0],
						  get_viewport_rect().size.x * zone_boundaries[1])
	
	var target_pos = Vector2(challenge_x, ball.global_position.y)
	velocity = delta * (target_pos - global_position).normalized() * sprint_speed
	move_and_slide()

func _attack_opponent(delta):
	if opponents.is_empty(): return
	
	# Find nearest opponent with ball
	var nearest: Node2D = null
	var min_dist = INF
	for opponent in opponents:
		if opponent.has_ball:
			var dist = global_position.distance_to(opponent.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = opponent
	
	if nearest:
		if min_dist < attack_range:
			_perform_attack(nearest)
		else:
			velocity = delta * (nearest.global_position - global_position).normalized() * sprint_speed
			move_and_slide()

func _perform_attack(target: Node2D):
	# Play attack animation
	# Apply stun to opponent or knock them back
	target.position += (target.global_position - global_position).normalized() * 100.0

func _manual_control(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = delta * input_dir * (sprint_speed if Input.is_action_pressed("sprint") else move_speed)
	move_and_slide() #TODO: if sprinting, ball will phase past player instead of blocking
	if Input.is_action_just_pressed("attack_ball") and ball and can_shoot:
		_take_shot()
	if Input.is_action_just_pressed("dive") and can_dive:
		_attempt_dive(input_dir)
	if Input.is_action_just_pressed("spin"):
		_spin_move(delta)
	if Input.is_action_just_pressed("attack_player"):
		_attack_nearest()

func _attempt_dive(direction: Vector2):
	if not can_dive: return
	
	can_dive = false
	velocity = direction.normalized() * dive_power
	move_and_slide()
	
	# Check for ball save
	if ball and global_position.distance_to(ball.global_position) < 80.0:
		var reflect_dir = (ball.global_position - global_position).normalized().bounce(direction)
		ball.apply_impulse(reflect_dir * 600.0)
	
	await get_tree().create_timer(dive_cooldown).timeout
	can_dive = true

func _take_shot():
	if not ball or not can_shoot: return
	
	var goal_pos = Vector2(get_viewport_rect().size.x - 50, get_viewport_rect().size.y/2)
	var shot_dir = (goal_pos - ball.global_position).normalized()
	ball.apply_impulse(shot_dir * shot_power)
	can_shoot = false
	await get_tree().create_timer(1.5).timeout
	can_shoot = true

func _process_spin(delta):
	spin_timer -= delta
	if spin_timer <= 0.0:
		is_spinning = false
	else:
		# Circular evasion movement
		rotation += delta * 15.0
		velocity = Vector2.RIGHT.rotated(rotation) * move_speed * 0.7
		move_and_slide()

func _attack_nearest():
	if opponents.is_empty(): return
	
	var nearest = opponents[0]
	var min_dist = global_position.distance_to(nearest.global_position)
	for opponent in opponents:
		var dist = global_position.distance_to(opponent.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = opponent
	
	if min_dist < attack_range:
		_perform_attack(nearest)

func change_state(new_state: GoalieState):
	goalie_state = new_state
	match new_state:
		GoalieState.DEFENSIVE:
			velocity = Vector2.ZERO
		GoalieState.AGGRESSIVE:
			pass
		GoalieState.VIOLENT:
			pass
		GoalieState.MANUAL:
			pass

func _on_zone_changed(new_zone: int):
	match new_zone:
		0:  # Defensive
			change_state(GoalieState.DEFENSIVE)
		1:  # Neutral
			change_state(GoalieState.AGGRESSIVE)
		2:  # Attacking
			change_state(GoalieState.VIOLENT)

func _on_ball_entered_range(ball_body: Ball):
	ball = ball_body

func _on_ball_exited_range(ball_body: Ball):
	if ball == ball_body:
		ball = null
